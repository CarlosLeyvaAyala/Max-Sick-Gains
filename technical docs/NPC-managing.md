# NPC managing

Apply to NPC:

```{}

if it's a known actor
  apply bodyslide
  apply muscle definition
else
  calculate appearance

```

Calculate appearance

```{}

if class is known
  if race is not excluded from fitness level
    apply bodyslide
    apply muscle definition
  else
    return invalid race
else
  return invalid class

```
Apply muscle definition

```{}

if user wants to apply muscle definition
  if this fitness type can be applyied to this race
    change skin to fitness type
```
