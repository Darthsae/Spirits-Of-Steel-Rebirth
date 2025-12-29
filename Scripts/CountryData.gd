extends Node
class_name CountryData

# =========================================================
# Stats
# =========================================================
var country_name: String
var political_power: int = 50
var money: float = 1000.0
var manpower: int = 50000
var stability: float = 0.5     # 0.0 to 1.0
var war_support: float = 0.5    # 0.0 to 1.0

# =========================================================
# Daily Gains
# =========================================================
var daily_pp_gain: int = 2
var daily_money_income: float = 1000
var daily_manpower_growth: int = 600

var allowedCountries: Array[String] = [] # for pathfinding

# =========================================================
# Training / Troop Pools
# =========================================================

# --- Training ---
class TroopTraining:
	var divisions: int
	var days_left: int
	var daily_cost: float
	
	func _init(_divisions: int, _days: int, _daily_cost: float):
		divisions = _divisions
		days_left = _days
		daily_cost = _daily_cost

# --- Ready (not deployed) ---
class ReadyTroop:
	var divisions: int
	
	func _init(_divisions: int):
		divisions = _divisions

var ongoing_training: Array[TroopTraining] = []
var ready_troops: Array[ReadyTroop] = []

# =========================================================
# Initialization
# =========================================================
func _init(p_name: String) -> void:
	country_name = p_name
	self.name = p_name
	allowedCountries.append(p_name)

# =========================================================
# Combat Modifiers (NEW)
# =========================================================
func get_max_morale() -> float:
	# Base morale is 60. Stability adds up to 40.
	# 100% Stability = 100 Morale. 0% Stability = 60 Morale.
	var base := 60.0 + (stability * 40.0)
	
	# Bankruptcy Penalty: 50% max morale if no money
	if money < 0:
		base *= 0.5
		
	return base

func get_attack_efficiency() -> float:
	# Base damage 1.0. War Support adds up to +20% or subtracts -10%.
	# 1.0 War Support = 1.2x Damage
	# 0.0 War Support = 0.9x Damage
	var eff := 0.9 + (war_support * 0.3)
	
	# Bankruptcy Penalty: -30% damage
	if money < 0:
		eff *= 0.7
		
	return eff

func get_defense_efficiency() -> float:
	# Stability aids defense organization.
	var eff := 1.0 + (stability * 0.15)
		
	if money < 0:
		eff *= 0.8
		
	return eff


# =========================================================
# Daily Turn Processing
# =========================================================
func process_turn() -> void:
	# --- Economy & population ---
	political_power += daily_pp_gain
	money += (daily_money_income - calculate_army_upkeep())
	manpower += daily_manpower_growth
	
	#stability += (0.75 - stability) * 0.01
	
	_process_training()

# =========================================================
# Training Logic
# =========================================================
func _process_training() -> void:
	# Pay & progress training
	for training in ongoing_training:
		var daily_cost := training.divisions * training.daily_cost
		
		# If we have money, pay and progress
		# You could allow debt here, but let's keep it strict
		if money >= daily_cost:
			money -= daily_cost
			training.days_left -= 1
		else:
			# Pause training if no money
			continue
	
	# Finish training → move to READY pool
	for i in range(ongoing_training.size() - 1, -1, -1):
		var training = ongoing_training[i]
		if training.days_left <= 0:
			ready_troops.append(ReadyTroop.new(training.divisions))
			ongoing_training.remove_at(i)

func calculate_army_upkeep() -> float:
	var total := 0.0
	for troop in TroopManager.get_troops_for_country(country_name):
		total += troop.divisions * 10
	return total

func train_troops(divisions: int, days: int, cost_per_day: float) -> bool:
	var manpower_needed := divisions * 10000
	var first_day_cost := divisions * cost_per_day
	
	if manpower < manpower_needed:
		return false
	if money < first_day_cost:
		return false
	
	# Reserve manpower immediately
	manpower -= manpower_needed
	
	# Pay first day upfront
	money -= first_day_cost
	
	ongoing_training.append(
		TroopTraining.new(divisions, days, cost_per_day)
	)
	
	return true

func deploy_ready_troops(index: int) -> bool:
	if index < 0 or index >= ready_troops.size():
		return false
	
	var troop := ready_troops[index]
	TroopManager.add_troops(country_name, troop.divisions)
	ready_troops.remove_at(index)
	return true

# Helpers
func spend_money(amount: float) -> bool:
	if money < amount:
		return false
	money -= amount
	return true

func spend_politicalpower (amount: int) -> bool:
	if political_power < amount:
		return false
	political_power -= amount
	return true

func get_total_ready_divisions() -> int:
	var total := 0
	for t in ready_troops:
		total += t.divisions
	return total

func get_total_training_divisions() -> int:
	var total := 0
	for t in ongoing_training:
		total += t.divisions
	return total
