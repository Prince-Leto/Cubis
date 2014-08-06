#encoding: UTF-8
module Cinch
  module Plugins
    class Cubis
      include Cinch::Plugin

      listen_to :message, method: :anwser
      listen_to :join, method: :on_join
      listen_to :part, :quit, :kill, method: :on_part

      def initialize(*)
        super
        @buffalo_time = 30
        @drink_time = 30
        @users = []
        @colors = [{ id: 2, color: "bleu" }, { id: 3, color: "vert" }, { id: 5, color: "rouge" }, { id: 7, color: "jaune" }]
      end

      def find_user(nick)
        @users.each do |user|
          if user[:nick] == nick
            return user
          end
        end
        return nil
      end

      def remove_hl(nick)
        return nick[0] + "\u0003" + nick[1..nick.length]
      end

      def find_color(name)
        @colors.each do |color|
          if color[:color] == name
            return color
          end
        end
        return nil
      end

      def quizz
        message = "Test de sobriété : "
        response = []
        10.times do |i|
          one = @colors[rand(@colors.length)]
          two = @colors[rand(@colors.length)]
          response.push(one[:id])
          message += "\u0003" + one[:id].to_s + two[:color] + " "
        end
        return [message, response]
      end

      def etat(m)
        unless @users.empty?
          response = "État : "
          @users.each do |user|
            response += remove_hl(user[:nick]) + " : " + user[:etat].to_s + " buffalo(s) | "
          end
          m.reply response[0..-4]
        end
      end

      def propre(m)
        unless @users.empty?
          response = "Propreté : "
          @users.each do |user|
            response += remove_hl(user[:nick]) + " " + user[:propre].to_s + " | "
          end
          m.reply response[0..-4]
        end
      end

      def anwser(m)
        puts m.channel
        if m.channel == "#cubis"
          sender = find_user m.user.nick
          on_join(m) if sender.nil?
          if m.message == '!etat'
            etat(m)
          elsif m.message == '!propre'
            propre(m)
          elsif m.message == "!replay" and sender[:propre] == 0
            r = quizz
            sender[:game] = r[1]
            m.reply r[0]
          elsif m.message =~ /!play\s(([^\s]+\s){9}[^\s]+)/ and sender[:propre] == 0
            res = []
            m.message.split(":")[1].split(" ").each do |color|
              res.push(find_color(color)[:id])
            end
            if res == sender[:game]
              sender[:propre] = 20
              m.reply remove_hl(sender[:nick]) + " est à nouveau propre."
            else
              m.reply "Try again"
            end
          elsif m.message =~ /^!water ([^\s]+)/ and sender[:propre] != 0
            u = find_user $~[1]
            if u != sender
              if u.nil?
                m.reply "Ce pseudo n'existe pas..."
              else
                now = Time.now.to_i
                if now - sender[:drink_time] >= @drink_time
                  sender[:drink_time] = now
                  u[:etat] -= 2
                  u[:etat] = 0 if u[:etat] < 0
                  sender[:etat] -= 1 unless sender[:etat] == 0
                else
                  m.reply remove_hl(sender[:nick]) + ", attends encore " + (@drink_time - now + sender[:drink_time]).to_s + " secondes"
                end
              end
            end
          elsif m.message =~ /^!buffalo ([^\s]+)/ and sender[:propre] != 0
            u = find_user $~[1]
            now = Time.now.to_i
            if u.nil?
              m.reply "Ce pseudo n'existe pas..."
            else
              if now - sender[:buf_time] >= @buffalo_time
                sender[:buf_time] = now - sender[:etat]*3
                if rand(3 + u[:etat]*2) == 0
                  m.reply "Pas de chance, " + remove_hl(u[:nick]) + " buvait de la bonne main. Tu bois !"
                  u = sender
                end
                u[:etat] += 1
                # etat(m)
                if rand(10 - u[:etat]) == 0
                  victime = @users[rand(@users.length)]
                  if victime == u
                    m.reply remove_hl(u[:nick]) + " s'est vomi dessus avec " + u[:etat].to_s + " verres dans le sang"
                  else
                    m.reply remove_hl(u[:nick]) + " a vomi " + u[:etat].to_s + " verres sur " + remove_hl(victime[:nick]) + " :)"
                  end
                  u[:propre] -= u[:etat]/2
                  u[:propre] = 0 if u[:propre] < 0
                  victime[:propre] -= u[:etat]
                  victime[:propre] = 0 if victime[:propre] < 0
                  u[:etat] = 0
                  # propre(m)
                end
              else
                m.reply remove_hl(sender[:nick]) + ", attends encore " + (@buffalo_time - now + sender[:buf_time]).to_s + " secondes"
              end
            end
          end
        end
      end

      def on_join(m)
        @users.push({ nick: m.user.nick, etat: 0, propre: 20, buf_time: 0 , drink_time: 0, game: [] })
      end

      def on_part(m)
        @users.remove(find_user m.user)
      end
    end
  end
end
