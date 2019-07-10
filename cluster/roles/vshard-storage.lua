#!/usr/bin/env tarantool

local log = require('log')
local vshard = require('vshard')
local checks = require('checks')

local vars = require('cluster.vars').new('cluster.roles.vshard-storage')
local utils = require('cluster.utils')
local vshard_utils = require('cluster.vshard-utils')

vars:new('vshard_cfg')

local function apply_config(conf)
    checks('table')

    local my_replicaset = conf.topology.replicasets[box.info.cluster.uuid]
    local group_name = my_replicaset.vshard_group or 'default'
    local vshard_cfg = vshard_utils.get_vshard_config(group_name, conf)
    vshard_cfg.listen = box.cfg.listen

    if utils.deepcmp(vshard_cfg, vars.vshard_cfg) then
        -- No reconfiguration required, skip it
        return
    end

    log.info('Reconfiguring vshard.storage...')
    vshard.storage.cfg(vshard_cfg, box.info.uuid)
    vars.vshard_cfg = vshard_cfg
end

local function init()
    rawset(_G, 'vshard', vshard)
end

local function stop()
    rawset(_G, 'vshard', nil)
end

return {
    role_name = 'vshard-storage',
    apply_config = apply_config,
    init = init,
    stop = stop,
}
