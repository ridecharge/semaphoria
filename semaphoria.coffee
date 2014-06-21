module.exports = (robot) ->
    robot.respond /lockstatus ([a-z]*?):([a-z]*)/i, (msg) ->
                msg.http("http://semaphoria.herokuapp.com/lock_status?app=#{msg.match[1]}&environment=#{msg.match[2]}")
                .headers(Accept: 'application/json')
                .get() (err, res, body) -> 
                  switch res.statusCode
                    when 200
                      json = JSON.parse(body)
                      if json.locked == true
                        lock_value = "was locked by #{json.by} at #{json.at}"  
                      else
                        lock_value = "is not locked"
                      msg.send("#{msg.match[1]} in #{msg.match[2]} #{lock_value}")
                    else
                      msg.send("Something went wrong, check your inputs.")
    robot.respond /lock ([a-z]*?):([a-z]*)/i, (msg) ->
                data = JSON.stringify({app: "#{msg.match[1]}", environment: "#{msg.match[2]}", user: "#{msg.message.user.name}"})
                msg.http("http://semaphoria.herokuapp.com/lock")
                .headers(Accept: 'application/json', 'Content-Type': 'application/json')
                .post(data) (err, res, body) ->
                  switch res.statusCode
                    when 200
                      msg.send("#{msg.match[1]} in #{msg.match[2]} was locked")
                    else
                      msg.send("Something went wrong, check your inputs.")
    robot.respond /unlock ([a-z]*?):([a-z]*)/i, (msg) ->
                data = JSON.stringify({app: "#{msg.match[1]}", environment: "#{msg.match[2]}", user: "#{msg.message.user.name}"})
                msg.http("http://semaphoria.herokuapp.com/lock")
                .headers(Accept: 'application/json', 'Content-Type': 'application/json')
                .put(data) (err, res, body) -> 
                  switch res.statusCode
                    when 200
                      msg.send("#{msg.match[1]} in #{msg.match[2]} was unlocked")
                    else
                      msg.send("Something went wrong, check your inputs.")