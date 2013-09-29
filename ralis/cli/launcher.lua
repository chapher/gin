require 'ralis.core.ralis'

local RalisLauncher = {}
RalisLauncher.nginx_conf_source = 'config/nginx.conf'
RalisLauncher.nginx_conf_tmp_dir = 'tmp'
RalisLauncher.dirs = {
    'logs',
    'tmp'
}

function RalisLauncher.start()
    RalisLauncher.create_dirs()
    RalisLauncher.create_nginx_conf()
    result = os.execute("nginx -p `pwd`/ -c " .. RalisLauncher.nginx_conf_file_path())
    if result == 0 and Ralis.env ~= 'test' then print("Ralis app was succesfully started.") end
end

function RalisLauncher.stop()
    result = os.execute("nginx -s stop -p `pwd`/ -c " .. RalisLauncher.nginx_conf_file_path())
    if Ralis.env ~= 'test' then
        if result == 0 then
            print("Ralis app was succesfully stopped.")
        else
            print("ERROR: Could not stop Ralis app (maybe not started?)")
        end
    end
    RalisLauncher.remove_nginx_conf()
end

function RalisLauncher.create_dirs()
    for _, dir in pairs(RalisLauncher.dirs) do
        lfs.mkdir(dir)
    end
end

function RalisLauncher.create_nginx_conf()
    -- read nginx.conf file
    local f = io.open(RalisLauncher.nginx_conf_source, "rb")
    local nginx_conf_template = f:read("*all")
    f:close()

    -- append notice
    nginx_conf_template = [[
# ===================================================================== #
# THIS FILE IS AUTO GENERATED. DO NOT MODIFY.                           #
# IF YOU CAN SEE IT, THERE PROBABLY IS A RUNNING SERVER REFERENCING IT. #
# ===================================================================== #

]] .. nginx_conf_template

    -- get conf params
    local conf_params = Ralis.conf_params()

    -- inject params in content
    local nginx_content = nginx_conf_template
    nginx_content = string.gsub(nginx_content, "{{RALIS_PORT}}", conf_params.port)
    nginx_content = string.gsub(nginx_content, "{{RALIS_ENV}}", Ralis.env)
    nginx_content = string.gsub(nginx_content, "{{WORKER_CONNECTIONS}}", conf_params.worker_connections)
    nginx_content = string.gsub(nginx_content, "{{WORKER_PROCESSES}}", conf_params.worker_processes)

    -- write conf file
    local fw = io.open(RalisLauncher.nginx_conf_file_path(), "w")
    fw:write(nginx_content)
    fw:close()
end

function RalisLauncher.remove_nginx_conf()
    os.remove(RalisLauncher.nginx_conf_file_path())
end

function RalisLauncher.nginx_conf_file_path()
    return RalisLauncher.nginx_conf_tmp_dir .. "/" .. Ralis.env .. "-nginx.conf"
end

return RalisLauncher