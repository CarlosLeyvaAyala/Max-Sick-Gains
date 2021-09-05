Scriptname Maxick__Addon_trainingWeightSpawn extends ObjectReference
{Create and place a new activator for the player to train.}

Import Math

Activator Property trainingWeight Auto
{Activator to spawn}

MiscObject Property spawner Auto
{Misc item that spawned the activator}

Event OnEquipped(Actor _)
  ObjectReference droppedActivator
  Actor player = Game.GetPlayer()
  droppedActivator = player.PlaceAtMe(trainingWeight)
  float theta = player.GetAngleZ()
  float r = 30
  If (droppedActivator)
    droppedActivator.MoveTo(player, r * Sin(theta), r * Cos(theta), 7.0)
    droppedActivator.SetAngle(0.0, 0.0, theta)
    player.RemoveItem(spawner, 1, True)
  EndIf
EndEvent
