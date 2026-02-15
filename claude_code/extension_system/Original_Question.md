Yes, Claude skills can clash with one another, primarily when multiple skills provide contradictory instructions or when different skills share the same name. Because skills act as loaded context, conflicts can arise if skills are not properly designed for coexistence. 
Here is how skills clash and how they are handled:
1. Types of Skill Clashes
Contradictory Instructions (Context Clashes): If you activate two skills that offer conflicting guidelines (e.g., one skill insists on writing in Python and another for the same project insists on TypeScript), it can derail Claude's reasoning.
Naming Conflicts: If multiple skills share the same name across different levels (e.g., personal vs. project), the higher-priority skill will win.
Inconsistent Versions: Using the same skill name for different logic across different platforms (Claude.ai vs. API vs. local) can cause unpredictable behavior.
Over-accumulation: Loading too many skills at once can overload the context, leading to inconsistent performance. 
2. How to Resolve Conflicts
Prioritize Skills: When naming collisions occur, higher-priority locations are used: Enterprise > Personal > Project.
Use Namespace for Plugins: Plugin skills use a plugin-name:skill-name format to prevent direct name collisions.
Use Specific Descriptions: Vague skill descriptions make it hard for Claude to pick the right one. The first paragraph of your SKILL.md is critical for ensuring the correct skill is invoked.
Use "Conflict Resolver" Skill: There is a dedicated, specialized skill available to help Claude identify and resolve technical disagreements between different agents or proposed solutions. 
3. Best Practices to Prevent Clashes
Design for Composition: Build skills to work alongside others, rather than assuming they are the only capability present.
Use Specificity: Make sure your SKILL.md file clearly defines when a skill should—and should not—be used.
Avoid Overlap: Ensure that skills are specialized and do not directly compete for the same task, unless they are designed to be used in a hierarchy. 
Note: If you have a file in .claude/commands/, it takes precedence if it shares a name with a skill. 