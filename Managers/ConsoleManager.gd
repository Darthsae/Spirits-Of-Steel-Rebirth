extends Node



func _ready() -> void:
	Console.add_command("play_country", CountryManager.set_player_country, ["country_name"])
	Console.add_command("set_speed", MainClock.set_speed, ["scale"])
	Console.add_command("set_political_power", CountryManager.set_political_power, ["country_name", "new_power"])
	Console.add_command("change_political_power", CountryManager.change_political_power, ["country_name", "power_change"])
