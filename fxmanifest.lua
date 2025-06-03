fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'K9 Script with ox_lib and ox_target'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'ox_target'
}