return function(): ()
    repeat
        task.wait(10000)
    until false
end
