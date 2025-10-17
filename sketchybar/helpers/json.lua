-- Simple JSON decoder for Lua
-- Based on public domain implementations

local json = {}

-- Decode JSON string to Lua table
function json.decode(str)
    local pos = 1

    local function decode_error(msg)
        error("JSON decode error at position " .. pos .. ": " .. msg)
    end

    local function skip_whitespace()
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then
                break
            end
            pos = pos + 1
        end
    end

    local function decode_value()
        skip_whitespace()
        local c = str:sub(pos, pos)

        if c == '"' then
            return decode_string()
        elseif c == "{" then
            return decode_object()
        elseif c == "[" then
            return decode_array()
        elseif c == "t" then
            return decode_literal("true", true)
        elseif c == "f" then
            return decode_literal("false", false)
        elseif c == "n" then
            return decode_literal("null", nil)
        elseif c == "-" or (c >= "0" and c <= "9") then
            return decode_number()
        else
            decode_error("unexpected character '" .. c .. "'")
        end
    end

    function decode_string()
        pos = pos + 1 -- skip opening quote
        local result = ""
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == '"' then
                pos = pos + 1
                return result
            elseif c == "\\" then
                pos = pos + 1
                local escape = str:sub(pos, pos)
                if escape == '"' or escape == "\\" or escape == "/" then
                    result = result .. escape
                elseif escape == "b" then
                    result = result .. "\b"
                elseif escape == "f" then
                    result = result .. "\f"
                elseif escape == "n" then
                    result = result .. "\n"
                elseif escape == "r" then
                    result = result .. "\r"
                elseif escape == "t" then
                    result = result .. "\t"
                else
                    decode_error("invalid escape sequence")
                end
                pos = pos + 1
            else
                result = result .. c
                pos = pos + 1
            end
        end
        decode_error("unterminated string")
    end

    function decode_number()
        local start = pos
        if str:sub(pos, pos) == "-" then
            pos = pos + 1
        end
        while pos <= #str and str:sub(pos, pos):match("[0-9]") do
            pos = pos + 1
        end
        if pos <= #str and str:sub(pos, pos) == "." then
            pos = pos + 1
            while pos <= #str and str:sub(pos, pos):match("[0-9]") do
                pos = pos + 1
            end
        end
        if pos <= #str and (str:sub(pos, pos) == "e" or str:sub(pos, pos) == "E") then
            pos = pos + 1
            if pos <= #str and (str:sub(pos, pos) == "+" or str:sub(pos, pos) == "-") then
                pos = pos + 1
            end
            while pos <= #str and str:sub(pos, pos):match("[0-9]") do
                pos = pos + 1
            end
        end
        return tonumber(str:sub(start, pos - 1))
    end

    function decode_literal(literal, value)
        if str:sub(pos, pos + #literal - 1) ~= literal then
            decode_error("expected '" .. literal .. "'")
        end
        pos = pos + #literal
        return value
    end

    function decode_array()
        pos = pos + 1 -- skip opening bracket
        skip_whitespace()
        local result = {}
        if str:sub(pos, pos) == "]" then
            pos = pos + 1
            return result
        end
        while true do
            table.insert(result, decode_value())
            skip_whitespace()
            local c = str:sub(pos, pos)
            if c == "]" then
                pos = pos + 1
                return result
            elseif c == "," then
                pos = pos + 1
            else
                decode_error("expected ',' or ']'")
            end
        end
    end

    function decode_object()
        pos = pos + 1 -- skip opening brace
        skip_whitespace()
        local result = {}
        if str:sub(pos, pos) == "}" then
            pos = pos + 1
            return result
        end
        while true do
            skip_whitespace()
            if str:sub(pos, pos) ~= '"' then
                decode_error("expected string key")
            end
            local key = decode_string()
            skip_whitespace()
            if str:sub(pos, pos) ~= ":" then
                decode_error("expected ':'")
            end
            pos = pos + 1
            result[key] = decode_value()
            skip_whitespace()
            local c = str:sub(pos, pos)
            if c == "}" then
                pos = pos + 1
                return result
            elseif c == "," then
                pos = pos + 1
            else
                decode_error("expected ',' or '}'")
            end
        end
    end

    return decode_value()
end

return json
