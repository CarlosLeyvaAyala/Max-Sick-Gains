# NPC managing

Apply to NPC:

```{}

if it's a known actor
  straight up apply configuration
else
  if race is not known
    stop; could be a spider or something
  else
    if class is known
      set bodyslide for that class
    else
      set default bodyslide

```

Apply muscle definition

```{}

if user wants to apply muscle definition
  if this fitness type can be applyied to this race
    change skin to fitness type
```
