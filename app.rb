require "sinatra"
require "slim"
enable :sessions

def creature_mutation(mutate_or_not_number)
    if mutate_or_not_number <= 15
        mutate = true
    else 
        return 0
    end
    if mutate == true
        if rand(1..2) == 1
            return -1
        else 
            return 1
        end
    end
end
def foodspots(food_amount, gridsize)
    i = 0
    food_x= []
    food_y=[]
    food_array = []
    while i < food_amount
        food_x[i] = rand(1..gridsize)
        food_y[i] = rand(1..gridsize)
        food_array[i] = [food_x[i], food_y[i]]
        i += 1
    end
    food_array = food_array.sort
    index = 0
    food_grid = []
    while index < gridsize
        k = 0
        while k < gridsize
            food_grid[index] = [index+1,0]
            k += 1
        end
        index += 1
    end
    j = 0
    while j < food_amount
        food_grid[food_array[j][0]*50 -50+food_array[j][1]] = food_array[j] 
        j += 1
    end
    return food_grid
end

def check_through_foodspots(food, creature)
    if food[creature.xpos*50-50 + creature.ypos] == [creature.xpos, creature.ypos]
        creature.got_food += 1
        food[creature.xpos*50-50 + creature.ypos] = [creature.xpos, 0]
    end
    return food
end
class Kreature
    def initialize(previousstamina, gridsize)
        if previousstamina == 1
            previousstamina = 2
        end
        @stamina = previousstamina + creature_mutation(rand(1..100))
        @times_moved = 0
        @lifespan = 10
        @got_food = 0
        @gridsize = gridsize
        @xpos = rand(1..gridsize)
        @ypos = rand(1..gridsize)
    end
    def move()
        moveXorY = rand (1..2)
        if moveXorY == 1
            if @xpos == @gridsize
                @xpos -= 1
            elsif @xpos == 1
                @xpos += 1
            else 
                if rand(1..2) == 1
                    @xpos += 1
                else
                    @xpos -= 1
                end
            end
        else
            if @ypos == @gridsize
                @ypos -= 1
            elsif @ypos == 1
                @ypos += 1
            else 
                if rand(1..2) == 1
                    @ypos += 1
                else
                    @ypos -= 1
                end
            end
        end
        @times_moved += 1
    end  
    def update()
        @times_moved = 0
        @got_food = 0
        @lifespan -= 1
    end
    attr_accessor :ypos
    attr_accessor :xpos
    attr_accessor :times_moved 
    attr_accessor :stamina
    attr_accessor :got_food
    attr_accessor :lifespan
end

def runsimulation(starting_creatures, food_req, gridsize, food_amount, current_day)
    # Under dagen
    food_spots = foodspots(food_amount, gridsize)
    i = 0
    creatures = starting_creatures
    while current_day+10 > i
        for creature in creatures
            if creature.times_moved != creature.stamina
                creature.move()
                food_spots = check_through_foodspots(food_spots, creature)
            end
        end
        i += 1  
    end    
    # Slut på dag
    temporary_array = []
    for creature in creatures
        if creature.got_food >= creature.stamina*food_req
            temporary_array.append(Kreature.new(creature.stamina, gridsize))
        else
            creature.lifespan = 0
        end
    end
    creatures.concat(temporary_array)
    current_day += 1
    j = 0
    newcreatures = []
    while j < creatures.length
        creatures[j].update()
        if creatures[j].lifespan > 0
            newcreatures.append(creatures[j])
        end
        j += 1
    end
    creatures = newcreatures
    unless creatures.length == 0
        p creatures[creatures.length-1].stamina
    end
    return [creatures, current_day]
end
simresult=[]
actual_res=[]
post("/runsimulation") do
    session.destroy
    actual_res=[]
    session[:num1] = params[:num1]
    session[:num2] = params[:num2]
    session[:num3] = params[:num3]
    session[:num4] = params[:num4]
    session[:num5] = params[:num5]
    session[:displaymethod] = params[:displaymethod]
    starting_creatures = session[:num1].to_i
    creatures = []
    simresult = []
    current_day = 0
    z = 0
    if params[:num1] == nil || params[:num2] = nil || params[:num3] = nil || params[:num4] = nil || params[:num5] = nil
        actual_res = nil
    end
    while starting_creatures > z
        creatures.append(Kreature.new(rand(1..10), session[:num4].to_i))
        z += 1
    end
    max_days = session[:num2].to_i
    
    while max_days > current_day
        simres = runsimulation(creatures, session[:num3].to_f/100, session[:num4].to_i, session[:num5].to_i, current_day)
        if creatures.length > 10000
            session[:result] = "crashed"
            redirect('/')
        end
        simdic = simres[0].map do |creature| 
            creatureinfo = {
            stamina:creature.stamina,
            lifespan:creature.lifespan,
            position:[creature.xpos, creature.ypos]
            }
        end
        simresult[current_day] = simdic
        creatures = simres[0]
        current_day = simres[1]
    end
    actual_res = simresult
    redirect('/')
end

get('/kill') do
    session.destroy
    redirect('/')
end

#get('/simulation/crash') do
#    slim(:nothing, locals:{result:actual_res})
#end
#
#get('/simulation/standard') do
#    slim(:standard, locals:{result:actual_res})
#end
#
#get('/simulation/graphs') do
#    slim(:graphs, locals:{result:actual_res})
#end
#
get('/') do
    slim(:layout, locals:{result:actual_res})
end

