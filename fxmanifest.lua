fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'RSG-fight'

version '1.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    -- 'locales/en.lua', -- Change to your language
    'config.lua',
}

server_script {
    'server/*.lua',
}

client_script {
    'client/*.lua',
}

dependencies {
    'rsg-core',
    'rsg-target',
    'ox_lib'
}



lua54 'yes'
