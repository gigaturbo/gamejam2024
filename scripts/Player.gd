extends CharacterBody2D

signal hitByRessource(ressource)
signal resourceEaten(ressource)
signal changeEvolution(playerEvolution, zoomMultiplierWhenBig, shakeMultiplierWhenBig, shakeSpeedMultiplierWhenBig)
signal hitByObstacle(obstacle)

# if level 1 : balanceLevelBis is ignored
# if level 2 : balanceLevel and balanceLevelBis used
signal pointMade(newScore, balanceLevel, balanceLevelBis)

# GAME PLAY
@export var speedLittle = 600 # in pix/sec
@export var speedBig = 1200 # in pix/sec

var maxSpeed = speedLittle


const mouseIdleLowLimit = 0.05 # relative distance (0 to 1) of the mouse from center to lateral border. This distant cause 0 maxSpeed
const mouseIdleHighLimit = 0.5 # relative distance (0 to 1) of the mouse from center to lateral border. This distant cause max maxSpeed


# which percentage to which the balance bar reach a step
const CVresourceStep1 = 0.2
const CVresourceStep2 = 0.1

const minRessourceToBeBig = 5

# /END GAMEPLAY

#  AFFICHAGE
var zoomMultiplierWhenBig = 0.75
var shakeMultiplierWhenBig = 1.15
var shakeSpeedMultiplierWhenBig = 7
# / end AFFICHAGE


var playerEvolution # TINY, LITTLE, BIG (= F0, F1, F2)
var playerMoveState = "idle" # eat, eat_poison, idle, walk_down, walk_lateral, walk_up

var screenSize 


var resource_counter_0 = 0
var resource_counter_1 = 0
var resource_counter_2 = 0
var resource_counter_3 = 0

var resource_counter_tot = 0

var score = 0

var level = 1

 # the balance bar
var coefficientOfVariationResource = 0.0
var pointMultiplier = 1.0 #

var isLookingLeft = false

var isApprearing = true

@onready var bigPlayerStepSounds = [$PlayerSounds/sound_big_step, 
									$PlayerSounds/sound_big_step2,
									$PlayerSounds/sound_big_step3,
									$PlayerSounds/sound_big_step4]

# called at start
func _ready():
	$AnimatedSprite2D.hide()
	setPlayerEvolution("LITTLE")
	
	
	$AnimatedSprite2D.animation = "F1_appear"
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play()
	screenSize = DisplayServer.window_get_size()

	$TimerAppear.start()



func _on_timer_appear_timeout():
	setPlayerMoveState("idle")
	isApprearing = false


func get_input():

	var mousePointingDirection = get_viewport().get_mouse_position() - screenSize*0.5
	var input_direction = mousePointingDirection.normalized() 
	
	# 0 to 1
	var mouseIntensity = mousePointingDirection.length() / (screenSize.x*0.5) 
	var speedResultOfMouse = 0
	
	# set animation according to mousePosition
	if(mouseIntensity <= mouseIdleLowLimit * 1.2):
		setPlayerMoveState("idle")
	else:
		setPlayerMoveState("walk_lateral")
		# Orientation
		$AnimatedSprite2D.set_flip_h(mousePointingDirection.x < 0)
		if mousePointingDirection.x < 0:
			$AnimatedSprite2D/CharacterEffects.scale.x = -abs($AnimatedSprite2D/CharacterEffects.scale.x)
		else:
			$AnimatedSprite2D/CharacterEffects.scale.x = abs($AnimatedSprite2D/CharacterEffects.scale.x)
		
	# maxSpeed
	if(mouseIntensity > mouseIdleLowLimit):
		speedResultOfMouse = (mouseIntensity - mouseIdleLowLimit) / (mouseIdleHighLimit - mouseIdleLowLimit) # from 0 to 1
	if(mouseIntensity > mouseIdleHighLimit):
		speedResultOfMouse = 1
	
	var maxVelocity = input_direction * maxSpeed
	velocity = lerp(Vector2(0,0), maxVelocity, speedResultOfMouse)
	
	
# each frame
func _physics_process(delta):
	
	# Movement
	if not isApprearing :
		get_input()
		move_and_slide()
		
		# Steps sound, 2 steps per 24 frames
		if velocity.length() > 0:
			
			# Setting animation framerate from speed
			$AnimatedSprite2D.speed_scale = (velocity.length()/maxSpeed) * 3
			
			# Playing sounds on steps 
			var sound
			match playerEvolution:
				"TINY":
					sound = $PlayerSounds/sound_small_step
					if ($AnimatedSprite2D.frame == 3) or ($AnimatedSprite2D.frame == 18):
						sound.play()
				"LITTLE":
					sound = $PlayerSounds/sound_small_step
					if ($AnimatedSprite2D.frame == 3) or ($AnimatedSprite2D.frame == 18):
						sound.play()
				"BIG":
					sound = bigPlayerStepSounds[randi_range(0,len(bigPlayerStepSounds)-1)]
					if ($AnimatedSprite2D.frame == 6) or ($AnimatedSprite2D.frame == 18):
						sound.play()
	
	
func setPlayerMoveState(moveState):
	var animName = ""
	match playerEvolution:
		"TINY":
			animName = "F0"
		"LITTLE":
			animName = "F1"
		"BIG":
			animName = "F2"
	
	$AnimatedSprite2D.animation = str(animName, "_", moveState)


# evolution level = TINY LITTLE or BIG
func setPlayerEvolution(playerEvolution_):
	
	if playerEvolution != playerEvolution_ :
			
		if playerEvolution == "LITTLE" || playerEvolution == "BIG":
			changeEvolution.emit(playerEvolution_, zoomMultiplierWhenBig, shakeMultiplierWhenBig, shakeSpeedMultiplierWhenBig)
			
			if playerEvolution_ == "LITTLE":
				$PlayerSounds/sound_shrink.play()
			if playerEvolution_ == "BIG":
				$PlayerSounds/sound_grow.play()
	
	playerEvolution = playerEvolution_
	match playerEvolution_:
		"TINY":
			$CollisionShape2D_F0.disabled = false
			$CollisionShape2D_F1.disabled = true
			$CollisionShape2D_F2.disabled = true
			$CollisionShape2D_F0.show()
			$CollisionShape2D_F1.hide()
			$CollisionShape2D_F2.hide()
			maxSpeed = 0
		"LITTLE":
			$CollisionShape2D_F0.disabled = true
			$CollisionShape2D_F1.disabled = false
			$CollisionShape2D_F2.disabled = true
			$CollisionShape2D_F0.hide()
			$CollisionShape2D_F1.show()
			$CollisionShape2D_F2.hide()
			maxSpeed = speedLittle
			$AnimatedSprite2D/CharacterEffects/PointLight2D_eat.position = Vector2(74.46, 193.594)
			$AnimatedSprite2D/CharacterEffects/PointLight2D_eat.scale = Vector2(1.455, 1.65)
		"BIG":
			$CollisionShape2D_F0.disabled = true
			$CollisionShape2D_F1.disabled = true
			$CollisionShape2D_F2.disabled = false
			$CollisionShape2D_F0.hide()
			$CollisionShape2D_F1.hide()
			$CollisionShape2D_F2.show()
			$AnimatedSprite2D/CharacterEffects/PointLight2D_eat.position = Vector2(89.352, -74.462)
			$AnimatedSprite2D/CharacterEffects/PointLight2D_eat.scale = Vector2(0.914,1.967)
			maxSpeed = speedBig
	setPlayerMoveState(playerMoveState)


func _on_hit_by_ressource(ressource):
	if ressource.slimeState == ressource.SlimeState.ALIVE: # avoid double hit
		var sound
		match playerEvolution:
			"TINY":
				sound = $PlayerSounds/sound_small_eat
				sound.play()
			"LITTLE":
				sound = $PlayerSounds/sound_small_eat
				if sound.finished:
					sound.play()
			"BIG":
				sound = $PlayerSounds/sound_big_eat
				if sound.finished:
					sound.play()
	pass


func _on_resource_eaten(ressource):
	
	$AnimatedSprite2D/CharacterEffects/PointLight2D_eat/AnimationPlayer.stop()
	$AnimatedSprite2D/CharacterEffects/PointLight2D_eat/AnimationPlayer.play("ligth_eating")
	
	
	ressource.slimeState = ressource.SlimeState.EATEN # TODO: already set in Resource ?
	
	resource_counter_tot += 1
	match ressource.slimeType:
		ressource.SlimeTypeEnum.NORMAL_BLUE:
			resource_counter_0 += 1
		ressource.SlimeTypeEnum.NORMAL_PINK:
			resource_counter_1 += 1
		ressource.SlimeTypeEnum.POISON_BLUE:
			resource_counter_2 += 1 
			# COMBO BREAKER
#			resource_counter_0 /= 2 
		ressource.SlimeTypeEnum.POISON_PINK:
			resource_counter_3 += 1 
			# COMBO BREAKER  
#			resource_counter_1 /= 2
	
	if ressource.isPoisonous:
		$PlayerSounds/sound_poisoned.play()
		# divide the shorter ressource
		if resource_counter_1 > resource_counter_0:
			resource_counter_0 /= 2
		else:
			resource_counter_1 /= 2
	
	var meanResource = 1.0
	var varianceResource = 0.0
	if(level == 1):
		meanResource = 0.5*(resource_counter_0 + resource_counter_1)
		varianceResource = 0.5 * ((resource_counter_0 - meanResource)**2 + (resource_counter_1 - meanResource)**2)
	
	var standDeviationResource = sqrt(varianceResource)
	coefficientOfVariationResource = standDeviationResource / meanResource
	
	if(coefficientOfVariationResource <= CVresourceStep2):
		pointMultiplier = 5
	elif(coefficientOfVariationResource <= CVresourceStep1):
		pointMultiplier = 3
	else:
		pointMultiplier = 1
	
	var gain = 10 * pointMultiplier
		
	score += 10 * pointMultiplier
	
	# positive when more blue
	var sign_level_1 = sign(resource_counter_0 - resource_counter_1)
	var balanceLevel = 0
	
	if(level == 1):
		balanceLevel = sign_level_1 * coefficientOfVariationResource
		pointMade.emit(score, balanceLevel, balanceLevel)
	

	if(abs(balanceLevel) < CVresourceStep1 && resource_counter_tot >= minRessourceToBeBig):
		setPlayerEvolution("BIG")
	else:
		setPlayerEvolution("LITTLE")
		
