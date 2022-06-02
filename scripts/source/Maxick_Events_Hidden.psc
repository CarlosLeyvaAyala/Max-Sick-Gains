; Event handling that isn't meant to be used by addon creators.
Scriptname Maxick_Events_Hidden extends Quest

string Property GAME_RELOADED = "Maxick_OnGameReloaded" AutoReadOnly
{
  **Activation**: After Max Sick Gains has fully reloaded all data it needs to work
  when reloading a saved game.
}
string Property GAME_INIT = "Maxick_OnGameInit" AutoReadOnly
{
  **Activation**: After Max Sick Gains has been installed or a new game has been started.
}
