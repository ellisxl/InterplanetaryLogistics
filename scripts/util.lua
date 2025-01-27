local util = {}

function util.increase()
    util.value = (util.value or 0) + 1
    return util.value
end

 
return util
