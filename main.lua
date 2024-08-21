
function love.load()
    love.window.setTitle("Tetris")
    love.window.setMode(400, 600)
    
    gridWidth = 10
    gridHeight = 20
    cellSize = 30
    grid = {}
    score = 0
    level = 1
    linesCleared = 0

    for y = 1, gridHeight do
        grid[y] = {}
        for x = 1, gridWidth do
            grid[y][x] = 0
        end
    end

    shapes = {
        {{1, 1, 1}, {0, 1, 0}}, -- T shape
        {{1, 1, 1, 1}},         -- I shape
        {{1, 1}, {1, 1}},       -- O shape
        {{0, 1, 1}, {1, 1, 0}}, -- S shape
        {{1, 1, 0}, {0, 1, 1}}, -- Z shape
        {{1, 1, 1}, {1, 0, 0}}, -- L shape
        {{1, 1, 1}, {0, 0, 1}}  -- J shape
    }

    currentShape = shapes[love.math.random(#shapes)]
    nextShape = shapes[love.math.random(#shapes)]
    currentX = math.floor(gridWidth / 2) - math.floor(#currentShape[1] / 2)
    currentY = 0
    dropTimer = 0
    dropInterval = 0.5
    softDrop = false
    ghostY = calculateGhostY()

    gameOver = false
end

function love.update(dt)
    if gameOver then return end

    dropTimer = dropTimer + dt
    if softDrop then
        dropInterval = 0.1
    else
        dropInterval = 0.5 - (level - 1) * 0.05
    end

    if dropTimer >= dropInterval then
        currentY = currentY + 1
        if checkCollision(currentShape, currentX, currentY) then
            placeShape(currentShape, currentX, currentY - 1)
            clearRows()
            newShape()
        end
        dropTimer = 0
    end

    ghostY = calculateGhostY()

    if love.keyboard.isDown("left") then
        if not checkCollision(currentShape, currentX - 1, currentY) then
            currentX = currentX - 1
        end
    elseif love.keyboard.isDown("right") then
        if not checkCollision(currentShape, currentX + 1, currentY) then
            currentX = currentX + 1
        end
    end
end

function love.draw()
    if gameOver then
        love.graphics.print("Game Over! Press R to Restart", 100, 300)
        return
    end

    for y = 1, gridHeight do
        for x = 1, gridWidth do
            if grid[y][x] == 1 then
                love.graphics.rectangle("fill", (x-1) * cellSize, (y-1) * cellSize, cellSize, cellSize)
            end
        end
    end

    -- Draw ghost piece
    love.graphics.setColor(1, 1, 1, 0.3)
    for y = 1, #currentShape do
        for x = 1, #currentShape[y] do
            if currentShape[y][x] == 1 then
                love.graphics.rectangle("fill", (currentX + x - 1) * cellSize, (ghostY + y - 1) * cellSize, cellSize, cellSize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)

    for y = 1, #currentShape do
        for x = 1, #currentShape[y] do
            if currentShape[y][x] == 1 then
                love.graphics.rectangle("fill", (currentX + x - 1) * cellSize, (currentY + y - 1) * cellSize, cellSize, cellSize)
            end
        end
    end

    love.graphics.print("Next:", 320, 10)
    for y = 1, #nextShape do
        for x = 1, #nextShape[y] do
            if nextShape[y][x] == 1 then
                love.graphics.rectangle("fill", 320 + x * cellSize, 30 + y * cellSize, cellSize, cellSize)
            end
        end
    end

    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Level: " .. level, 10, 30)
end

function checkCollision(shape, x, y)
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if shape[i][j] == 1 then
                local gridX = x + j
                local gridY = y + i
                if gridX < 1 or gridX > gridWidth or gridY > gridHeight or grid[gridY][gridX] == 1 then
                    return true
                end
            end
        end
    end
    return false
end

function placeShape(shape, x, y)
    for i = 1, #shape do
        for j = 1, #shape[i] do
            if shape[i][j] == 1 then
                grid[y + i][x + j] = 1
            end
        end
    end
end

function clearRows()
    local rowsCleared = 0
    for y = gridHeight, 1, -1 do
        local full = true
        for x = 1, gridWidth do
            if grid[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            rowsCleared = rowsCleared + 1
            for yy = y, 2, -1 do
                grid[yy] = grid[yy - 1]
            end
            grid[1] = {}
            for x = 1, gridWidth do
                grid[1][x] = 0
            end
            y = y + 1
        end
    end
    score = score + rowsCleared * 100 * level
    linesCleared = linesCleared + rowsCleared
    if linesCleared >= 10 then
        level = level + 1
        linesCleared = 0
    end
end

function newShape()
    currentShape = nextShape
    nextShape = shapes[love.math.random(#shapes)]
    currentX = math.floor(gridWidth / 2) - math.floor(#currentShape[1] / 2)
    currentY = 0
    ghostY = calculateGhostY()
    if checkCollision(currentShape, currentX, currentY) then
        gameOver = true
    end
end

function rotateShape(shape)
    local newShape = {}
    for x = 1, #shape[1] do
        newShape[x] = {}
        for y = 1, #shape do
            newShape[x][y] = shape[#shape - y + 1][x]
        end
    end
    return newShape
end

function calculateGhostY()
    local y = currentY
    while not checkCollision(currentShape, currentX, y) do
        y = y + 1
    end
    return y - 1
end

function love.keypressed(key)
    if key == "r" and gameOver then
        love.load()
    elseif key == "up" then
        local rotatedShape = rotateShape(currentShape)
        if not checkCollision(rotatedShape, currentX, currentY) then
            currentShape = rotatedShape
            ghostY = calculateGhostY()
        end
    elseif key == "left" then
        if not checkCollision(currentShape, currentX - 1, currentY) then
            currentX = currentX - 1
            ghostY = calculateGhostY()
        end
    elseif key == "right" then
        if not checkCollision(currentShape, currentX + 1, currentY) then
            currentX = currentX + 1
            ghostY = calculateGhostY()
        end
    elseif key == "down" then
        softDrop = true
    elseif key == "space" then
        currentY = ghostY
        dropTimer = dropInterval
    end
end

function love.keyreleased(key)
    if key == "down" then
        softDrop = false
    end
end
