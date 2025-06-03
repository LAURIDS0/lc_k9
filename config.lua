Config = {}

-- K9 Dog Model
Config.DogModel = 'a_c_shepherd' -- German Shepherd Dog model

-- K9 Animations
Config.Animations = {
    Sit = {
        dict = "creatures@rottweiler@amb@world_dog_sitting@idle_a",
        anim = "idle_a"
    },
    Bark = {
        dict = "creatures@rottweiler@amb@world_dog_barking@idle_a",
        anim = "idle_a"
    },
    Follow = {
        dict = "creatures@rottweiler@amb@follow_owner@",
        anim = "follow_owner"
    }
}

-- K9 Commands
Config.Commands = {
    Sit = "k9sit",
    Follow = "k9follow",
    Search = "k9search",
    Enter = "k9vehicle",
    Exit = "k9exit"
}

-- Items that K9 can detect
Config.DetectableItems = {
    -- Drugs
    'weed_brick',
    'coke_brick',
    'meth',
    'oxy',
    -- Weapons
    'weapon_pistol',
    'weapon_smg',
    'weapon_rifle',
    'weapon_assaultrifle'
}

-- Jobs allowed to use K9
Config.AllowedJobs = {
    ['police'] = true,
    ['sheriff'] = true
}

-- Search settings
Config.SearchDistance = 5.0 -- How far the dog will search for items
Config.SearchTime = 5000 -- Time in ms that the search takes
