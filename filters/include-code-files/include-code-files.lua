--[[
Copyright (c) 2021, Gabriel Soldani

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

SPDX-License-Identifier: ISC
]]--

PANDOC_VERSION:must_be_at_least "2.12"

pandoc.path = require("pandoc.path")
local unicode_text = require("text")

--
-- Reads from the given file name.
--
-- The following search order is used:
--     1. Absolute paths
--     2. Relative paths to the current working directory.
--     3. Relative paths to the directory of each input file, in order.
--
-- On success, returns the contents of the file as a string.
-- On failure, returns a pair of nil and err, where err is the first error
-- returned by a call to io.open.
--
local function read_file (filename)
    -- 1 and 2. Absolute and relative paths
    local file, err = io.open(filename, "r")

    if file == nil then
        -- 3. Relative paths to directory of each input file
        for _, input_filename in ipairs(PANDOC_STATE.input_files) do
            local directory = pandoc.path.directory(input_filename)
            file = pandoc.system.with_working_directory(directory, function ()
                return io.open(filename, "r")
            end)
        end
    end

    if file == nil then
        return nil, err
    end

    local content = file:read("a")

    file:close()

    return content, nil
end

--
-- Makes a string suitable for an identifier from a string.
-- Identifiers can't have spaces and should be lower case.
--
local function idify (s)
    local id = ""
    for i = 1, unicode_text.len(s) do
        local codepoint = unicode_text.sub(s, i, i)
        id = id .. (codepoint ~= " " and codepoint or "-")
    end
    return unicode_text.lower(id)
end

local function CodeBlock (elem)
    local filename = elem.attributes.include
    local title = elem.attributes.title or elem.classes:includes("title")

    if filename == nil then
        return pandoc.CodeBlock(elem.text, elem.attr)
    end

    -- Pop our custom attributes and classes so they don't get passed further
    -- down to other filters
    elem.attributes.include = nil
    elem.attributes.title = nil
    elem.classes = elem.classes:filter(function (class)
        return class ~= "title"
    end)

    local content, err = read_file(filename)
    assert(err == nil, err)

    local codeblock = pandoc.CodeBlock(content, elem.attr)

    if title then
        local header_text = title == true and filename or title
        local header = pandoc.Header(6, pandoc.Str(header_text), pandoc.Attr(idify(header_text), {".code--header"}))
        return { header, codeblock }
    end

    return codeblock
end

return {{ CodeBlock = CodeBlock }}
