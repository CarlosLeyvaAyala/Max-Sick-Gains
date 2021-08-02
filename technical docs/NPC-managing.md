# NPC managing

Apply to NPC:

```{}

if it's a known actor
  if not banned
    apply bodyslide
    apply muscle definition
  else
    return "banned"
else
  calculate appearance

```

Calculate appearance

```{}

if race is known
  if class is known
    try set class
  else
    try set default bodyslide
else
  return "Invalid race. Enable in 'exe > Races' if you want this race to be processed."

```
Apply muscle definition

```{}

if user wants to apply muscle definition
  if this fitness type can be applyied to this race
    change skin to fitness type
```
