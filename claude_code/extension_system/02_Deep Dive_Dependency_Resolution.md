# Deep Dive: Dependency Resolution, MCP Integration, and Testing Strategies

Let me elaborate on the three critical aspects of the architecture with comprehensive implementations.

---

## Part 1: Advanced Dependency Resolution

### Dependency Graph Builder

```python
# registry/dependency_resolver.py
from typing import Dict, List, Set, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import re
from packaging import version
from packaging.specifiers import SpecifierSet
import networkx as nx
import logging

class DependencyType(Enum):
    PYTHON_PACKAGE = "python_package"
    SYSTEM_PACKAGE = "system_package"
    PLUGIN = "plugin"
    SKILL = "skill"
    HOOK = "hook"

@dataclass
class Dependency:
    name: str
    type: DependencyType
    version_spec: str  # e.g., ">=1.0.0,<2.0.0"
    required_by: str
    optional: bool = False
    metadata: Dict = field(default_factory=dict)

@dataclass
class ResolvedDependency:
    name: str
    type: DependencyType
    resolved_version: str
    installation_source: str  # e.g., "pypi", "conda", "apt"
    conflicts: List[str] = field(default_factory=list)
    dependents: List[str] = field(default_factory=list)

class DependencyResolver:
    def __init__(self, registry: ExtensionRegistry):
        self.registry = registry
        self.dependency_graph = nx.DiGraph()
        self.resolved: Dict[str, ResolvedDependency] = {}
        self.logger = logging.getLogger(__name__)
        
    def build_dependency_graph(self):
        """Build complete dependency graph for all plugins"""
        
        # Add plugin nodes
        for plugin_id, plugin in self.registry.plugins.items():
            self.dependency_graph.add_node(
                plugin_id,
                type='plugin',
                version=plugin.version
            )
            
            # Add Python package dependencies
            for package_spec in plugin.dependencies.get('python', []):
                dep = self._parse_dependency_spec(package_spec)
                dep_node = f"py:{dep.name}"
                
                if not self.dependency_graph.has_node(dep_node):
                    self.dependency_graph.add_node(
                        dep_node,
                        type='python_package',
                        name=dep.name
                    )
                    
                self.dependency_graph.add_edge(
                    plugin_id,
                    dep_node,
                    version_spec=dep.version_spec,
                    dependency_type=DependencyType.PYTHON_PACKAGE
                )
                
            # Add system dependencies
            for sys_package in plugin.dependencies.get('system', []):
                sys_node = f"sys:{sys_package}"
                
                if not self.dependency_graph.has_node(sys_node):
                    self.dependency_graph.add_node(
                        sys_node,
                        type='system_package',
                        name=sys_package
                    )
                    
                self.dependency_graph.add_edge(
                    plugin_id,
                    sys_node,
                    dependency_type=DependencyType.SYSTEM_PACKAGE
                )
                
            # Add plugin dependencies
            for plugin_dep in plugin.requires:
                dep_plugin_id = plugin_dep['plugin']
                version_spec = plugin_dep.get('version', '*')
                
                if dep_plugin_id in self.registry.plugins:
                    self.dependency_graph.add_edge(
                        plugin_id,
                        dep_plugin_id,
                        version_spec=version_spec,
                        dependency_type=DependencyType.PLUGIN
                    )
                else:
                    self.logger.warning(
                        f"Plugin {plugin_id} requires missing plugin: {dep_plugin_id}"
                    )
                    
            # Add skill dependencies (internal to plugin)
            for component in plugin.components:
                if component.type == ComponentType.SKILL:
                    comp_node = f"skill:{component.id}"
                    self.dependency_graph.add_node(
                        comp_node,
                        type='skill',
                        plugin_id=plugin_id
                    )
                    
                    # Add edges for skill dependencies
                    for dep_skill_id in component.dependencies:
                        dep_node = f"skill:{dep_skill_id}"
                        if self.dependency_graph.has_node(dep_node):
                            self.dependency_graph.add_edge(
                                comp_node,
                                dep_node,
                                dependency_type=DependencyType.SKILL
                            )
                            
    def _parse_dependency_spec(self, spec: str) -> Dependency:
        """Parse dependency specification like 'numpy>=1.20.0,<2.0.0'"""
        
        # Match package name and version spec
        match = re.match(r'^([a-zA-Z0-9_-]+)(.*)$', spec.strip())
        if not match:
            raise ValueError(f"Invalid dependency spec: {spec}")
            
        name = match.group(1)
        version_spec = match.group(2).strip() or '*'
        
        return Dependency(
            name=name,
            type=DependencyType.PYTHON_PACKAGE,
            version_spec=version_spec,
            required_by=""
        )
        
    def resolve_dependencies(self) -> Dict[str, ResolvedDependency]:
        """Resolve all dependencies and detect conflicts"""
        
        self.build_dependency_graph()
        
        # Check for circular dependencies
        try:
            cycles = list(nx.simple_cycles(self.dependency_graph))
            if cycles:
                raise CircularDependencyError(
                    f"Circular dependencies detected: {cycles}"
                )
        except nx.NetworkXNoCycle:
            pass  # No cycles, good
            
        # Topologically sort dependencies
        try:
            sorted_nodes = list(nx.topological_sort(self.dependency_graph))
        except nx.NetworkXError as e:
            raise DependencyResolutionError(f"Cannot resolve dependencies: {e}")
            
        # Resolve each dependency
        for node in sorted_nodes:
            node_data = self.dependency_graph.nodes[node]
            node_type = node_data.get('type')
            
            if node_type == 'python_package':
                self._resolve_python_package(node)
            elif node_type == 'system_package':
                self._resolve_system_package(node)
            elif node_type == 'plugin':
                self._resolve_plugin(node)
                
        return self.resolved
        
    def _resolve_python_package(self, node: str):
        """Resolve Python package with version constraints"""
        
        package_name = self.dependency_graph.nodes[node]['name']
        
        # Collect all version constraints from dependents
        constraints = []
        dependents = []
        
        for predecessor in self.dependency_graph.predecessors(node):
            edge_data = self.dependency_graph.edges[predecessor, node]
            version_spec = edge_data.get('version_spec', '*')
            constraints.append(version_spec)
            dependents.append(predecessor)
            
        # Find compatible version
        try:
            resolved_version = self._find_compatible_version(
                package_name,
                constraints
            )
            
            self.resolved[node] = ResolvedDependency(
                name=package_name,
                type=DependencyType.PYTHON_PACKAGE,
                resolved_version=resolved_version,
                installation_source='pypi',
                dependents=dependents
            )
            
            self.logger.info(
                f"Resolved {package_name} to version {resolved_version}"
            )
            
        except VersionConflictError as e:
            self.logger.error(f"Version conflict for {package_name}: {e}")
            
            # Create resolved entry with conflicts
            self.resolved[node] = ResolvedDependency(
                name=package_name,
                type=DependencyType.PYTHON_PACKAGE,
                resolved_version="CONFLICT",
                installation_source='pypi',
                conflicts=[str(e)],
                dependents=dependents
            )
            
    def _find_compatible_version(
        self,
        package_name: str,
        constraints: List[str]
    ) -> str:
        """Find a version that satisfies all constraints"""
        
        # Combine all specifiers
        combined_spec = SpecifierSet(','.join(constraints))
        
        # In production, query PyPI for available versions
        # For now, simulate with common versions
        available_versions = self._get_available_versions(package_name)
        
        # Find the latest version that satisfies all constraints
        compatible_versions = [
            v for v in available_versions
            if version.parse(v) in combined_spec
        ]
        
        if not compatible_versions:
            raise VersionConflictError(
                f"No version of {package_name} satisfies: {constraints}"
            )
            
        # Return latest compatible version
        return max(compatible_versions, key=version.parse)
        
    def _get_available_versions(self, package_name: str) -> List[str]:
        """Get available versions for a package (mock implementation)"""
        
        # In production, query PyPI API
        # https://pypi.org/pypi/{package_name}/json
        
        # Mock data for common packages
        mock_versions = {
            'numpy': ['1.19.0', '1.20.0', '1.21.0', '1.22.0', '1.23.0', '1.24.0'],
            'pandas': ['1.3.0', '1.4.0', '1.5.0', '2.0.0', '2.1.0'],
            'requests': ['2.26.0', '2.27.0', '2.28.0', '2.31.0'],
        }
        
        return mock_versions.get(package_name, ['1.0.0'])
        
    def _resolve_system_package(self, node: str):
        """Resolve system package dependencies"""
        
        package_name = self.dependency_graph.nodes[node]['name']
        dependents = list(self.dependency_graph.predecessors(node))
        
        self.resolved[node] = ResolvedDependency(
            name=package_name,
            type=DependencyType.SYSTEM_PACKAGE,
            resolved_version='latest',
            installation_source='apt',  # or 'brew', 'yum', etc.
            dependents=dependents
        )
        
    def _resolve_plugin(self, node: str):
        """Resolve plugin dependencies"""
        
        plugin = self.registry.plugins[node]
        dependents = list(self.dependency_graph.predecessors(node))
        
        self.resolved[node] = ResolvedDependency(
            name=plugin.name,
            type=DependencyType.PLUGIN,
            resolved_version=plugin.version,
            installation_source='local',
            dependents=dependents
        )
        
    def generate_installation_plan(self) -> Dict[str, List[str]]:
        """Generate installation commands for each plugin"""
        
        installation_plan = {}
        
        for plugin_id, plugin in self.registry.plugins.items():
            commands = []
            
            # System packages
            sys_packages = []
            for node in self.dependency_graph.successors(plugin_id):
                if self.dependency_graph.nodes[node].get('type') == 'system_package':
                    pkg_name = self.dependency_graph.nodes[node]['name']
                    sys_packages.append(pkg_name)
                    
            if sys_packages:
                commands.append(f"apt-get install -y {' '.join(sys_packages)}")
                
            # Python packages
            py_packages = []
            for node in self.dependency_graph.successors(plugin_id):
                if node.startswith('py:'):
                    resolved = self.resolved.get(node)
                    if resolved and resolved.resolved_version != 'CONFLICT':
                        py_packages.append(
                            f"{resolved.name}=={resolved.resolved_version}"
                        )
                        
            if py_packages:
                commands.append(f"uv pip install {' '.join(py_packages)}")
                
            installation_plan[plugin_id] = commands
            
        return installation_plan
        
    def visualize_dependency_graph(self, output_file: str = 'dependencies.png'):
        """Generate visual representation of dependency graph"""
        
        try:
            import matplotlib.pyplot as plt
            
            plt.figure(figsize=(16, 12))
            
            # Color nodes by type
            color_map = {
                'plugin': '#4CAF50',
                'python_package': '#2196F3',
                'system_package': '#FF9800',
                'skill': '#9C27B0'
            }
            
            node_colors = [
                color_map.get(self.dependency_graph.nodes[node].get('type'), '#gray')
                for node in self.dependency_graph.nodes()
            ]
            
            # Layout
            pos = nx.spring_layout(self.dependency_graph, k=2, iterations=50)
            
            # Draw
            nx.draw(
                self.dependency_graph,
                pos,
                node_color=node_colors,
                with_labels=True,
                node_size=3000,
                font_size=8,
                font_weight='bold',
                arrows=True,
                edge_color='#CCCCCC',
                arrowsize=20
            )
            
            plt.title('Plugin Dependency Graph', fontsize=16)
            plt.tight_layout()
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            plt.close()
            
            self.logger.info(f"Dependency graph saved to {output_file}")
            
        except ImportError:
            self.logger.warning("matplotlib not available, skipping visualization")
            
    def generate_dependency_report(self) -> str:
        """Generate detailed dependency report"""
        
        report = []
        report.append("=" * 80)
        report.append("DEPENDENCY RESOLUTION REPORT")
        report.append("=" * 80)
        
        # Summary
        total_deps = len(self.resolved)
        conflicts = sum(1 for d in self.resolved.values() if d.conflicts)
        
        report.append(f"\n📊 Summary:")
        report.append(f"   Total dependencies: {total_deps}")
        report.append(f"   Conflicts: {conflicts}")
        report.append(f"   Plugins: {len(self.registry.plugins)}")
        
        # By type
        by_type = {}
        for dep in self.resolved.values():
            if dep.type not in by_type:
                by_type[dep.type] = []
            by_type[dep.type].append(dep)
            
        for dep_type, deps in by_type.items():
            report.append(f"\n📦 {dep_type.value.upper()} ({len(deps)})")
            report.append("-" * 80)
            
            for dep in sorted(deps, key=lambda d: d.name):
                status = "✅" if not dep.conflicts else "❌"
                report.append(
                    f"   {status} {dep.name} → {dep.resolved_version}"
                )
                
                if dep.dependents:
                    report.append(
                        f"      Required by: {', '.join(dep.dependents[:3])}"
                        + (f" (+{len(dep.dependents)-3} more)" if len(dep.dependents) > 3 else "")
                    )
                    
                if dep.conflicts:
                    for conflict in dep.conflicts:
                        report.append(f"      ⚠️  {conflict}")
                        
        # Installation plan
        report.append("\n🔧 INSTALLATION PLAN")
        report.append("=" * 80)
        
        plan = self.generate_installation_plan()
        for plugin_id, commands in plan.items():
            report.append(f"\n{plugin_id}:")
            for cmd in commands:
                report.append(f"   $ {cmd}")
                
        return "\n".join(report)

class VersionConflictError(Exception):
    pass

class CircularDependencyError(Exception):
    pass

class DependencyResolutionError(Exception):
    pass
```

### Environment Isolation Manager

```python
# managers/environment_manager.py
import subprocess
import os
import json
from pathlib import Path
from typing import Dict, List, Optional
import logging

class EnvironmentManager:
    def __init__(self, base_path: str = "./environments"):
        self.base_path = Path(base_path)
        self.base_path.mkdir(exist_ok=True)
        self.logger = logging.getLogger(__name__)
        
    def create_plugin_environment(
        self,
        plugin_id: str,
        python_version: str,
        dependencies: List[str]
    ) -> Path:
        """Create isolated environment for a plugin using uv"""
        
        env_path = self.base_path / plugin_id
        env_path.mkdir(exist_ok=True)
        
        self.logger.info(f"Creating environment for {plugin_id}")
        
        # Create uv environment
        try:
            # Initialize uv project
            subprocess.run(
                ['uv', 'init', '--python', python_version],
                cwd=env_path,
                check=True,
                capture_output=True
            )
            
            # Create virtual environment
            subprocess.run(
                ['uv', 'venv'],
                cwd=env_path,
                check=True,
                capture_output=True
            )
            
            # Install dependencies
            if dependencies:
                subprocess.run(
                    ['uv', 'pip', 'install'] + dependencies,
                    cwd=env_path,
                    check=True,
                    capture_output=True
                )
                
            # Lock dependencies
            subprocess.run(
                ['uv', 'pip', 'freeze'],
                cwd=env_path,
                check=True,
                capture_output=True,
                stdout=open(env_path / 'requirements.lock', 'w')
            )
            
            self.logger.info(f"Environment created at {env_path}")
            return env_path
            
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to create environment: {e}")
            raise EnvironmentCreationError(
                f"Cannot create environment for {plugin_id}: {e}"
            )
            
    def create_docker_environment(
        self,
        plugin_id: str,
        plugin_path: Path,
        base_image: str = "python:3.11-slim"
    ) -> str:
        """Create Docker container for a plugin"""
        
        dockerfile_path = plugin_path / "Dockerfile"
        
        if not dockerfile_path.exists():
            # Generate Dockerfile
            self._generate_dockerfile(
                plugin_path,
                base_image,
                plugin_id
            )
            
        # Build Docker image
        image_tag = f"claude-plugin-{plugin_id}:latest"
        
        try:
            subprocess.run(
                ['docker', 'build', '-t', image_tag, '.'],
                cwd=plugin_path,
                check=True,
                capture_output=True
            )
            
            self.logger.info(f"Docker image built: {image_tag}")
            return image_tag
            
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to build Docker image: {e}")
            raise EnvironmentCreationError(
                f"Cannot build Docker image for {plugin_id}: {e}"
            )
            
    def _generate_dockerfile(
        self,
        plugin_path: Path,
        base_image: str,
        plugin_id: str
    ):
        """Generate Dockerfile for plugin"""
        
        dockerfile_content = f"""
FROM {base_image}

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    && rm -rf /var/lib/apt/lists/*

# Copy plugin files
COPY . .

# Install Python dependencies
RUN pip install uv
RUN uv pip install --system -r requirements.txt

# Set environment
ENV PLUGIN_ID={plugin_id}

# Run plugin
CMD ["python", "main.py"]
"""
        
        with open(plugin_path / "Dockerfile", 'w') as f:
            f.write(dockerfile_content.strip())
            
    def get_environment_info(self, plugin_id: str) -> Dict:
        """Get information about plugin environment"""
        
        env_path = self.base_path / plugin_id
        
        if not env_path.exists():
            return {'exists': False}
            
        info = {
            'exists': True,
            'path': str(env_path),
            'type': 'uv'
        }
        
        # Check for lock file
        lock_file = env_path / 'requirements.lock'
        if lock_file.exists():
            with open(lock_file) as f:
                info['locked_dependencies'] = f.read().splitlines()
                
        return info
        
    def cleanup_environment(self, plugin_id: str):
        """Remove plugin environment"""
        
        env_path = self.base_path / plugin_id
        
        if env_path.exists():
            import shutil
            shutil.rmtree(env_path)
            self.logger.info(f"Removed environment for {plugin_id}")

class EnvironmentCreationError(Exception):
    pass
```

---

## Part 2: MCP Server Integration Layer

### MCP Server Manager

```python
# managers/mcp_manager.py
import asyncio
import json
import subprocess
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import logging
from pathlib import Path

@dataclass
class MCPServerConfig:
    server_id: str
    plugin_id: str
    command: str
    args: List[str]
    env: Dict[str, str]
    working_dir: Path
    isolation_type: str

@dataclass
class MCPServerProcess:
    config: MCPServerConfig
    process: asyncio.subprocess.Process
    stdin: asyncio.StreamWriter
    stdout: asyncio.StreamReader
    stderr: asyncio.StreamReader
    
class MCPServerManager:
    def __init__(self, registry: ExtensionRegistry):
        self.registry = registry
        self.servers: Dict[str, MCPServerProcess] = {}
        self.logger = logging.getLogger(__name__)
        
    async def start_server(self, plugin_id: str) -> MCPServerProcess:
        """Start MCP server for a plugin"""
        
        plugin = self.registry.plugins.get(plugin_id)
        if not plugin:
            raise MCPServerError(f"Plugin {plugin_id} not found")
            
        # Get MCP server configuration from plugin manifest
        mcp_config = self._load_mcp_config(plugin)
        
        # Prepare environment
        env = os.environ.copy()
        env.update(mcp_config.env)
        env['PLUGIN_ID'] = plugin_id
        env['NAMESPACE'] = plugin.namespace
        
        # Start server process
        try:
            if mcp_config.isolation_type == 'uv':
                process = await self._start_uv_server(mcp_config, env)
            elif mcp_config.isolation_type == 'docker':
                process = await self._start_docker_server(mcp_config, env)
            else:
                process = await self._start_process_server(mcp_config, env)
                
            server_process = MCPServerProcess(
                config=mcp_config,
                process=process,
                stdin=process.stdin,
                stdout=process.stdout,
                stderr=process.stderr
            )
            
            self.servers[plugin_id] = server_process
            
            # Wait for server initialization
            await self._wait_for_initialization(server_process)
            
            self.logger.info(f"MCP server started for {plugin_id}")
            return server_process
            
        except Exception as e:
            self.logger.error(f"Failed to start MCP server for {plugin_id}: {e}")
            raise MCPServerError(f"Cannot start server: {e}")
            
    async def _start_uv_server(
        self,
        config: MCPServerConfig,
        env: Dict[str, str]
    ) -> asyncio.subprocess.Process:
        """Start MCP server in uv environment"""
        
        cmd = ['uv', 'run'] + config.args
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=config.working_dir,
            env=env
        )
        
        return process
        
    async def _start_docker_server(
        self,
        config: MCPServerConfig,
        env: Dict[str, str]
    ) -> asyncio.subprocess.Process:
        """Start MCP server in Docker container"""
        
        # Build docker run command
        cmd = ['docker', 'run', '--rm', '-i']
        
        # Add environment variables
        for key, value in env.items():
            cmd.extend(['-e', f'{key}={value}'])
            
        # Add image and command
        cmd.extend(config.args)
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        return process
        
    async def _start_process_server(
        self,
        config: MCPServerConfig,
        env: Dict[str, str]
    ) -> asyncio.subprocess.Process:
        """Start MCP server as standalone process"""
        
        process = await asyncio.create_subprocess_exec(
            config.command,
            *config.args,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=config.working_dir,
            env=env
        )
        
        return process
        
    def _load_mcp_config(self, plugin: Plugin) -> MCPServerConfig:
        """Load MCP server configuration from plugin"""
        
        manifest_path = Path(plugin.path) / 'plugin.yaml'
        with open(manifest_path) as f:
            manifest = yaml.safe_load(f)
            
        mcp_config = manifest['plugin'].get('mcp_server', {})
        
        if not mcp_config.get('enabled'):
            raise MCPServerError(f"MCP server not enabled for {plugin.id}")
            
        # Determine command based on isolation type
        if plugin.isolation == IsolationType.UV:
            command = 'uv'
            args = ['run', mcp_config['entry_point']]
        elif plugin.isolation == IsolationType.DOCKER:
            command = 'docker'
            args = ['run', '--rm', '-i', f'claude-plugin-{plugin.id}:latest']
        else:
            command = 'python'
            args = [mcp_config['entry_point']]
            
        return MCPServerConfig(
            server_id=f"{plugin.namespace}_mcp",
            plugin_id=plugin.id,
            command=command,
            args=args,
            env=mcp_config.get('env', {}),
            working_dir=Path(plugin.path),
            isolation_type=plugin.isolation.value
        )
        
    async def _wait_for_initialization(
        self,
        server_process: MCPServerProcess,
        timeout: float = 10.0
    ):
        """Wait for MCP server to initialize"""
        
        try:
            # Send initialize request
            init_request = {
                'jsonrpc': '2.0',
                'id': 1,
                'method': 'initialize',
                'params': {
                    'protocolVersion': '2024-11-05',
                    'capabilities': {},
                    'clientInfo': {
                        'name': 'claude-extension-manager',
                        'version': '1.0.0'
                    }
                }
            }
            
            await self._send_message(server_process, init_request)
            
            # Wait for response
            response = await asyncio.wait_for(
                self._read_message(server_process),
                timeout=timeout
            )
            
            if 'error' in response:
                raise MCPServerError(
                    f"Initialization failed: {response['error']}"
                )
                
            self.logger.debug(f"Server initialized: {server_process.config.server_id}")
            
        except asyncio.TimeoutError:
            raise MCPServerError("Server initialization timeout")
            
    async def _send_message(
        self,
        server_process: MCPServerProcess,
        message: Dict
    ):
        """Send JSON-RPC message to MCP server"""
        
        message_str = json.dumps(message) + '\n'
        server_process.stdin.write(message_str.encode())
        await server_process.stdin.drain()
        
    async def _read_message(
        self,
        server_process: MCPServerProcess
    ) -> Dict:
        """Read JSON-RPC message from MCP server"""
        
        line = await server_process.stdout.readline()
        if not line:
            raise MCPServerError("Server closed connection")
            
        return json.loads(line.decode())
        
    async def call_tool(
        self,
        plugin_id: str,
        tool_name: str,
        arguments: Dict[str, Any]
    ) -> Any:
        """Call a tool on an MCP server"""
        
        server = self.servers.get(plugin_id)
        if not server:
            raise MCPServerError(f"Server not running for {plugin_id}")
            
        request = {
            'jsonrpc': '2.0',
            'id': self._generate_request_id(),
            'method': 'tools/call',
            'params': {
                'name': tool_name,
                'arguments': arguments
            }
        }
        
        await self._send_message(server, request)
        response = await self._read_message(server)
        
        if 'error' in response:
            raise MCPServerError(f"Tool call failed: {response['error']}")
            
        return response.get('result')
        
    async def list_tools(self, plugin_id: str) -> List[Dict]:
        """List available tools from an MCP server"""
        
        server = self.servers.get(plugin_id)
        if not server:
            raise MCPServerError(f"Server not running for {plugin_id}")
            
        request = {
            'jsonrpc': '2.0',
            'id': self._generate_request_id(),
            'method': 'tools/list',
            'params': {}
        }
        
        await self._send_message(server, request)
        response = await self._read_message(server)
        
        if 'error' in response:
            raise MCPServerError(f"Failed to list tools: {response['error']}")
            
        return response.get('result', {}).get('tools', [])
        
    async def read_resource(
        self,
        plugin_id: str,
        resource_uri: str
    ) -> Any:
        """Read a resource from an MCP server"""
        
        server = self.servers.get(plugin_id)
        if not server:
            raise MCPServerError(f"Server not running for {plugin_id}")
            
        request = {
            'jsonrpc': '2.0',
            'id': self._generate_request_id(),
            'method': 'resources/read',
            'params': {
                'uri': resource_uri
            }
        }
        
        await self._send_message(server, request)
        response = await self._read_message(server)
        
        if 'error' in response:
            raise MCPServerError(f"Failed to read resource: {response['error']}")
            
        return response.get('result')
        
    async def stop_server(self, plugin_id: str):
        """Stop MCP server for a plugin"""
        
        server = self.servers.get(plugin_id)
        if not server:
            return
            
        try:
            # Send shutdown notification
            shutdown_msg = {
                'jsonrpc': '2.0',
                'method': 'shutdown',
                'params': {}
            }
            await self._send_message(server, shutdown_msg)
            
            # Wait for graceful shutdown
            await asyncio.wait_for(server.process.wait(), timeout=5.0)
            
        except asyncio.TimeoutError:
            # Force kill if not responding
            server.process.kill()
            await server.process.wait()
            
        finally:
            del self.servers[plugin_id]
            self.logger.info(f"MCP server stopped for {plugin_id}")
            
    async def stop_all_servers(self):
        """Stop all running MCP servers"""
        
        for plugin_id in list(self.servers.keys()):
            await self.stop_server(plugin_id)
            
    def _generate_request_id(self) -> int:
        """Generate unique request ID"""
        if not hasattr(self, '_request_counter'):
            self._request_counter = 0
        self._request_counter += 1
        return self._request_counter
        
    async def health_check(self, plugin_id: str) -> bool:
        """Check if MCP server is healthy"""
        
        server = self.servers.get(plugin_id)
        if not server:
            return False
            
        try:
            # Send ping
            request = {
                'jsonrpc': '2.0',
                'id': self._generate_request_id(),
                'method': 'ping',
                'params': {}
            }
            
            await self._send_message(server, request)
            response = await asyncio.wait_for(
                self._read_message(server),
                timeout=2.0
            )
            
            return 'error' not in response
            
        except Exception as e:
            self.logger.warning(f"Health check failed for {plugin_id}: {e}")
            return False

class MCPServerError(Exception):
    pass
```

### MCP Server Router

```python
# managers/mcp_router.py
from typing import Dict, List, Any, Optional
import asyncio
import logging

class MCPRouter:
    """Route requests to appropriate MCP servers based on namespaces"""
    
    def __init__(
        self,
        mcp_manager: MCPServerManager,
        registry: ExtensionRegistry
    ):
        self.mcp_manager = mcp_manager
        self.registry = registry
        self.tool_registry: Dict[str, str] = {}  # tool_name -> plugin_id
        self.resource_registry: Dict[str, str] = {}  # resource_uri -> plugin_id
        self.logger = logging.getLogger(__name__)
        
    async def initialize(self):
        """Initialize router and build routing tables"""
        
        # Start all MCP servers
        for plugin_id in self.registry.plugins.keys():
            try:
                await self.mcp_manager.start_server(plugin_id)
                await self._register_server_capabilities(plugin_id)
            except Exception as e:
                self.logger.error(f"Failed to start server for {plugin_id}: {e}")
                
    async def _register_server_capabilities(self, plugin_id: str):
        """Register tools and resources from a server"""
        
        # Register tools
        tools = await self.mcp_manager.list_tools(plugin_id)
        for tool in tools:
            tool_name = tool['name']
            
            if tool_name in self.tool_registry:
                self.logger.warning(
                    f"Tool name conflict: {tool_name} already registered"
                )
            else:
                self.tool_registry[tool_name] = plugin_id
                self.logger.debug(f"Registered tool: {tool_name} -> {plugin_id}")
                
        # Register resources (from plugin manifest)
        plugin = self.registry.plugins[plugin_id]
        manifest_path = Path(plugin.path) / 'plugin.yaml'
        with open(manifest_path) as f:
            manifest = yaml.safe_load(f)
            
        resources = manifest['plugin'].get('mcp_server', {}).get('resources', [])
        for resource_pattern in resources:
            self.resource_registry[resource_pattern] = plugin_id
            
    async def call_tool(
        self,
        tool_name: str,
        arguments: Dict[str, Any]
    ) -> Any:
        """Route tool call to appropriate server"""
        
        plugin_id = self.tool_registry.get(tool_name)
        if not plugin_id:
            raise ToolNotFoundError(f"Tool '{tool_name}' not found")
            
        return await self.mcp_manager.call_tool(plugin_id, tool_name, arguments)
        
    async def read_resource(self, resource_uri: str) -> Any:
        """Route resource read to appropriate server"""
        
        plugin_id = self._match_resource_pattern(resource_uri)
        if not plugin_id:
            raise ResourceNotFoundError(f"No server handles resource: {resource_uri}")
            
        return await self.mcp_manager.read_resource(plugin_id, resource_uri)
        
    def _match_resource_pattern(self, resource_uri: str) -> Optional[str]:
        """Match resource URI to registered patterns"""
        
        import fnmatch
        
        for pattern, plugin_id in self.resource_registry.items():
            if fnmatch.fnmatch(resource_uri, pattern):
                return plugin_id
                
        return None
        
    async def list_all_tools(self) -> Dict[str, List[Dict]]:
        """List all available tools grouped by plugin"""
        
        all_tools = {}
        
        for plugin_id in self.registry.plugins.keys():
            try:
                tools = await self.mcp_manager.list_tools(plugin_id)
                all_tools[plugin_id] = tools
            except Exception as e:
                self.logger.error(f"Failed to list tools for {plugin_id}: {e}")
                all_tools[plugin_id] = []
                
        return all_tools
        
    def get_tool_info(self, tool_name: str) -> Optional[Dict]:
        """Get information about a specific tool"""
        
        plugin_id = self.tool_registry.get(tool_name)
        if not plugin_id:
            return None
            
        return {
            'tool_name': tool_name,
            'plugin_id': plugin_id,
            'namespace': self.registry.plugins[plugin_id].namespace
        }

class ToolNotFoundError(Exception):
    pass

class ResourceNotFoundError(Exception):
    pass
```

---

## Part 3: Comprehensive Testing Strategies

### Unit Tests

```python
# tests/test_registry.py
import pytest
from registry.extension_registry import ExtensionRegistry, Component, ComponentType
from registry.conflict_detector import ConflictDetector, ConflictSeverity

class TestExtensionRegistry:
    
    @pytest.fixture
    def registry(self):
        return ExtensionRegistry()
        
    @pytest.fixture
    def sample_plugin_path(self, tmp_path):
        """Create a sample plugin for testing"""
        plugin_dir = tmp_path / "test_plugin"
        plugin_dir.mkdir()
        
        manifest = {
            'plugin': {
                'id': 'test_plugin',
                'name': 'Test Plugin',
                'version': '1.0.0',
                'namespace': 'test',
                'isolation': {'type': 'uv', 'python_version': '3.11'},
                'dependencies': {
                    'python': ['numpy>=1.20.0']
                },
                'skills': [
                    {
                        'id': 'test_skill',
                        'name': 'Test Skill',
                        'entry_point': 'skills.test:TestSkill',
                        'priority': 10
                    }
                ],
                'hooks': [
                    {
                        'id': 'test_hook',
                        'type': 'pre_processing',
                        'entry_point': 'hooks.test:TestHook',
                        'priority': 50
                    }
                ]
            }
        }
        
        import yaml
        with open(plugin_dir / 'plugin.yaml', 'w') as f:
            yaml.dump(manifest, f)
            
        return plugin_dir
        
    def test_register_plugin(self, registry, sample_plugin_path):
        """Test plugin registration"""
        plugin = registry.register_plugin(str(sample_plugin_path))
        
        assert plugin.id == 'test_plugin'
        assert plugin.namespace == 'test'
        assert len(plugin.components) == 2  # 1 skill + 1 hook
        
    def test_namespace_conflict(self, registry, sample_plugin_path, tmp_path):
        """Test namespace conflict detection"""
        # Register first plugin
        registry.register_plugin(str(sample_plugin_path))
        
        # Create second plugin with same namespace
        plugin2_dir = tmp_path / "test_plugin2"
        plugin2_dir.mkdir()
        
        manifest = {
            'plugin': {
                'id': 'test_plugin2',
                'name': 'Test Plugin 2',
                'version': '1.0.0',
                'namespace': 'test',  # Same namespace!
                'isolation': {'type': 'uv', 'python_version': '3.11'},
                'skills': []
            }
        }
        
        import yaml
        with open(plugin2_dir / 'plugin.yaml', 'w') as f:
            yaml.dump(manifest, f)
            
        # Should raise error
        with pytest.raises(Exception) as exc_info:
            registry.register_plugin(str(plugin2_dir))
            
        assert 'namespace' in str(exc_info.value).lower()
        
    def test_get_components_by_type(self, registry, sample_plugin_path):
        """Test filtering components by type"""
        registry.register_plugin(str(sample_plugin_path))
        
        skills = registry.get_components_by_type(ComponentType.SKILL)
        hooks = registry.get_components_by_type(ComponentType.HOOK)
        
        assert len(skills) == 1
        assert len(hooks) == 1
        assert skills[0].id == 'test.test_skill'
        assert hooks[0].id == 'test.test_hook'

class TestConflictDetector:
    
    @pytest.fixture
    def registry_with_conflicts(self, tmp_path):
        """Create registry with intentional conflicts"""
        registry = ExtensionRegistry()
        
        # Plugin 1
        plugin1_dir = tmp_path / "plugin1"
        plugin1_dir.mkdir()
        manifest1 = {
            'plugin': {
                'id': 'plugin1',
                'name': 'Plugin 1',
                'version': '1.0.0',
                'namespace': 'p1',
                'isolation': {'type': 'uv', 'python_version': '3.11'},
                'dependencies': {
                    'python': ['numpy==1.20.0']
                },
                'skills': [
                    {
                        'id': 'analyze',
                        'name': 'Analyze',
                        'entry_point': 'skills:Analyze',
                        'priority': 10
                    }
                ]
            }
        }
        
        import yaml
        with open(plugin1_dir / 'plugin.yaml', 'w') as f:
            yaml.dump(manifest1, f)
            
        # Plugin 2 with conflicting numpy version
        plugin2_dir = tmp_path / "plugin2"
        plugin2_dir.mkdir()
        manifest2 = {
            'plugin': {
                'id': 'plugin2',
                'name': 'Plugin 2',
                'version': '1.0.0',
                'namespace': 'p2',
                'isolation': {'type': 'uv', 'python_version': '3.11'},
                'dependencies': {
                    'python': ['numpy==1.24.0']  # Different version!
                },
                'skills': [
                    {
                        'id': 'analyze',  # Same name!
                        'name': 'Analyze',
                        'entry_point': 'skills:Analyze',
                        'priority': 10
                    }
                ]
            }
        }
        
        with open(plugin2_dir / 'plugin.yaml', 'w') as f:
            yaml.dump(manifest2, f)
            
        registry.register_plugin(str(plugin1_dir))
        registry.register_plugin(str(plugin2_dir))
        
        return registry
        
    def test_detect_dependency_conflicts(self, registry_with_conflicts):
        """Test dependency conflict detection"""
        detector = ConflictDetector(registry_with_conflicts)
        conflicts = detector.detect_all_conflicts()
        
        # Should detect numpy version conflict
        dep_conflicts = [c for c in conflicts if c.type == 'dependency_version_conflict']
        assert len(dep_conflicts) > 0
        
    def test_detect_name_conflicts(self, registry_with_conflicts):
        """Test component name conflict detection"""
        detector = ConflictDetector(registry_with_conflicts)
        conflicts = detector.detect_all_conflicts()
        
        # Should detect skill name conflict
        name_conflicts = [c for c in conflicts if c.type == 'name_collision']
        assert len(name_conflicts) > 0
        
    def test_generate_report(self, registry_with_conflicts):
        """Test conflict report generation"""
        detector = ConflictDetector(registry_with_conflicts)
        conflicts = detector.detect_all_conflicts()
        report = detector.generate_report()
        
        assert 'CONFLICT DETECTION REPORT' in report
        assert 'numpy' in report.lower()
```

### Integration Tests

```python
# tests/test_integration.py
import pytest
import asyncio
from pathlib import Path

class TestFullIntegration:
    
    @pytest.fixture
    async def full_system(self, tmp_path):
        """Set up complete system with multiple plugins"""
        
        # Create test plugins
        plugins = await self._create_test_plugins(tmp_path)
        
        # Initialize system
        registry = ExtensionRegistry()
        for plugin_path in plugins:
            registry.register_plugin(str(plugin_path))
            
        # Initialize managers
        skill_manager = SkillManager(registry)
        hook_manager = HookManager(registry)
        mcp_manager = MCPServerManager(registry)
        
        await hook_manager.register_hooks()
        
        return {
            'registry': registry,
            'skill_manager': skill_manager,
            'hook_manager': hook_manager,
            'mcp_manager': mcp_manager
        }
        
    async def _create_test_plugins(self, tmp_path):
        """Create functional test plugins"""
        
        plugins = []
        
        # Plugin 1: Data processor
        plugin1_dir = tmp_path / "data_processor"
        plugin1_dir.mkdir()
        (plugin1_dir / "skills").mkdir()
        (plugin1_dir / "hooks").mkdir()
        
        # Create skill
        with open(plugin1_dir / "skills" / "processor.py", 'w') as f:
            f.write("""
from managers.skill_manager import SkillBase, SkillExecutionContext

class DataProcessor(SkillBase):
    async def execute(self, context):
        data = context.input_data
        return {'processed': data.upper()}
""")
        
        # Create hook
        with open(plugin1_dir / "hooks" / "pre_process.py", 'w') as f:
            f.write("""
from managers.hook_manager import HookBase, HookContext

class PreProcessHook(HookBase):
    async def execute(self, context):
        return context.data.strip()
""")
        
        # Create manifest
        manifest = {
            'plugin': {
                'id': 'data_processor',
                'name': 'Data Processor',
                'version': '1.0.0',
                'namespace': 'data',
                'isolation': {'type': 'uv', 'python_version': '3.11'},
                'skills': [
                    {
                        'id': 'process',
                        'name': 'Process Data',
                        'entry_point': 'skills.processor:DataProcessor',
                        'priority': 10
                    }
                ],
                'hooks': [
                    {
                        'id': 'pre_process',
                        'type': 'pre_processing',
                        'entry_point': 'hooks.pre_process:PreProcessHook',
                        'priority': 100
                    }
                ]
            }
        }
        
        import yaml
        with open(plugin1_dir / 'plugin.yaml', 'w') as f:
            yaml.dump(manifest, f)
            
        plugins.append(plugin1_dir)
        
        return plugins
        
    @pytest.mark.asyncio
    async def test_end_to_end_execution(self, full_system):
        """Test complete execution flow with hooks and skills"""
        
        hook_manager = full_system['hook_manager']
        skill_manager = full_system['skill_manager']
        
        # Input data
        input_data = "  hello world  "
        
        # Pre-process with hooks
        processed = await hook_manager.execute_hooks(
            HookType.PRE_PROCESSING,
            input_data
        )
        
        # Execute skill
        result = await skill_manager.execute_skill(
            'data.process',
            processed
        )
        
        # Verify
        assert result['processed'] == 'HELLO WORLD'
        
    @pytest.mark.asyncio
    async def test_mcp_server_lifecycle(self, full_system):
        """Test MCP server start, call, and stop"""
        
        mcp_manager = full_system['mcp_manager']
        
        # Start server
        await mcp_manager.start_server('data_processor')
        
        # Verify server is running
        assert 'data_processor' in mcp_manager.servers
        
        # Health check
        is_healthy = await mcp_manager.health_check('data_processor')
        assert is_healthy
        
        # Stop server
        await mcp_manager.stop_server('data_processor')
        
        # Verify server stopped
        assert 'data_processor' not in mcp_manager.servers
```

### Performance Tests

```python
# tests/test_performance.py
import pytest
import asyncio
import time
from typing import List

class TestPerformance:
    
    @pytest.mark.asyncio
    async def test_concurrent_skill_execution(self, full_system):
        """Test concurrent execution of multiple skills"""
        
        skill_manager = full_system['skill_manager']
        
        # Execute 100 skills concurrently
        start_time = time.time()
        
        tasks = [
            skill_manager.execute_skill('data.process', f"test_{i}")
            for i in range(100)
        ]
        
        results = await asyncio.gather(*tasks)
        
        elapsed = time.time() - start_time
        
        # Should complete in reasonable time (< 5 seconds)
        assert elapsed < 5.0
        assert len(results) == 100
        
    @pytest.mark.asyncio
    async def test_hook_chain_performance(self, full_system):
        """Test performance of hook chains"""
        
        hook_manager = full_system['hook_manager']
        
        # Execute hook chain 1000 times
        start_time = time.time()
        
        for i in range(1000):
            await hook_manager.execute_hooks(
                HookType.PRE_PROCESSING,
                f"test_{i}"
            )
            
        elapsed = time.time() - start_time
        
        # Should average < 1ms per execution
        avg_time = elapsed / 1000
        assert avg_time < 0.001
        
    def test_registry_lookup_performance(self, full_system):
        """Test component lookup performance"""
        
        registry = full_system['registry']
        
        # Lookup 10000 components
        start_time = time.time()
        
        for i in range(10000):
            components = registry.get_components_by_type(ComponentType.SKILL)
            
        elapsed = time.time() - start_time
        
        # Should be very fast (< 100ms total)
        assert elapsed < 0.1
```

### Stress Tests

```python
# tests/test_stress.py
import pytest
import asyncio
import random

class TestStressConditions:
    
    @pytest.mark.asyncio
    async def test_many_plugins(self, tmp_path):
        """Test system with many plugins (50+)"""
        
        registry = ExtensionRegistry()
        
        # Create 50 plugins
        for i in range(50):
            plugin_dir = tmp_path / f"plugin_{i}"
            plugin_dir.mkdir()
            
            manifest = {
                'plugin': {
                    'id': f'plugin_{i}',
                    'name': f'Plugin {i}',
                    'version': '1.0.0',
                    'namespace': f'p{i}',
                    'isolation': {'type': 'uv', 'python_version': '3.11'},
                    'skills': [
                        {
                            'id': f'skill_{j}',
                            'name': f'Skill {j}',
                            'entry_point': f'skills:Skill{j}',
                            'priority': random.randint(1, 100)
                        }
                        for j in range(5)  # 5 skills per plugin
                    ]
                }
            }
            
            import yaml
            with open(plugin_dir / 'plugin.yaml', 'w') as f:
                yaml.dump(manifest, f)
                
            registry.register_plugin(str(plugin_dir))
            
        # Verify all registered
        assert len(registry.plugins) == 50
        assert len(registry.components) == 250  # 50 plugins * 5 skills
        
        # Test conflict detection performance
        detector = ConflictDetector(registry)
        start_time = time.time()
        conflicts = detector.detect_all_conflicts()
        elapsed = time.time() - start_time
        
        # Should complete in reasonable time
        assert elapsed < 5.0
        
    @pytest.mark.asyncio
    async def test_rapid_server_restart(self, full_system):
        """Test rapid MCP server restart cycles"""
        
        mcp_manager = full_system['mcp_manager']
        
        # Restart server 20 times rapidly
        for i in range(20):
            await mcp_manager.start_server('data_processor')
            await asyncio.sleep(0.1)
            await mcp_manager.stop_server('data_processor')
            await asyncio.sleep(0.1)
            
        # System should remain stable
        assert len(mcp_manager.servers) == 0
        
    @pytest.mark.asyncio
    async def test_memory_leak(self, full_system):
        """Test for memory leaks during extended operation"""
        
        import psutil
        import os
        
        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        skill_manager = full_system['skill_manager']
        
        # Execute 10000 operations
        for i in range(10000):
            await skill_manager.execute_skill('data.process', f"test_{i}")
            
            if i % 1000 == 0:
                # Force garbage collection
                import gc
                gc.collect()
                
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        # Memory increase should be reasonable (< 50MB)
        assert memory_increase < 50
```

### Test Utilities

```python
# tests/conftest.py
import pytest
import asyncio
from pathlib import Path
import shutil

@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def temp_workspace(tmp_path):
    """Create temporary workspace for tests"""
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    
    yield workspace
    
    # Cleanup
    if workspace.exists():
        shutil.rmtree(workspace)

@pytest.fixture
def mock_claude_config(tmp_path):
    """Create mock Claude configuration"""
    config = {
        'mcpServers': {},
        'context_window': 100000,
        'max_tokens': 4096
    }
    
    config_path = tmp_path / "claude_config.json"
    import json
    with open(config_path, 'w') as f:
        json.dump(config, f)
        
    return config_path

# Test helpers
class PluginBuilder:
    """Helper to build test plugins"""
    
    def __init__(self, base_path: Path):
        self.base_path = base_path
        
    def create_plugin(
        self,
        plugin_id: str,
        namespace: str,
        skills: List[Dict] = None,
        hooks: List[Dict] = None,
        dependencies: Dict = None
    ) -> Path:
        """Create a test plugin with specified components"""
        
        plugin_dir = self.base_path / plugin_id
        plugin_dir.mkdir(exist_ok=True)
        
        manifest = {
            'plugin': {
                'id': plugin_id,
                'name': plugin_id.replace('_', ' ').title(),
                'version': '1.0.0',
                'namespace': namespace,
                'isolation': {'type': 'uv', 'python_version': '3.11'},
                'dependencies': dependencies or {},
                'skills': skills or [],
                'hooks': hooks or []
            }
        }
        
        import yaml
        with open(plugin_dir / 'plugin.yaml', 'w') as f:
            yaml.dump(manifest, f)
            
        return plugin_dir

@pytest.fixture
def plugin_builder(tmp_path):
    return PluginBuilder(tmp_path)
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']
        
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
          
      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh
        
      - name: Install dependencies
        run: |
          uv pip install pytest pytest-asyncio pytest-cov
          uv pip install -r requirements.txt
          
      - name: Run unit tests
        run: pytest tests/test_*.py -v --cov=. --cov-report=xml
        
      - name: Run integration tests
        run: pytest tests/test_integration.py -v
        
      - name: Run performance tests
        run: pytest tests/test_performance.py -v
        
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          
  conflict-detection:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Detect conflicts
        run: |
          python -m registry.conflict_detector --config config/plugins.yaml
          
  docker-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker images
        run: |
          for plugin in plugins/*/; do
            if [ -f "$plugin/Dockerfile" ]; then
              docker build -t "test-$(basename $plugin)" "$plugin"
            fi
          done
```

This comprehensive elaboration provides:

✅ **Advanced dependency resolution** with version conflict detection
✅ **Complete MCP server integration** with routing and lifecycle management
✅ **Comprehensive testing strategies** covering unit, integration, performance, and stress tests
✅ **CI/CD integration** for automated testing
✅ **Test utilities and fixtures** for easy test creation

Would you like me to add more details on any specific aspect, such as implementing a plugin marketplace, adding telemetry/observability, or creating a web-based management UI?