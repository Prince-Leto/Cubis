#encoding: UTF-8
module Cinch
  module Plugins
    class Cubis
      include Cinch::Plugin

      listen_to :message, method: :anwser
      listen_to :join, method: :on_join
      listen_to :leaving, method: :on_part

      def initialize(*)
        super
        @buffalo_time = 30
        @drink_time = 60
        @users = []
        @memory = []
        @hide = []
        @hide_time = 10
        @colors = [{ id: 2, color: "bleu" }, { id: 3, color: "vert" }, { id: 5, color: "rouge" }, { id: 7, color: "jaune" }]
        @phrases = [method(:drink_one), method(:drink_two), method(:drink_three), method(:drink_four), method(:drink_five), method(:drink_six), method(:drink_seven), method(:drink_eight), method(:drink_nine)]
        restart_vote
      end

      def find_user nick, array
        array.each do |user|
          if user[:nick] == nick
            return user
          end
        end
        return nil
      end

      def remove_hl nick
        return nick[0] + "\u0003" + nick[1..nick.length]
      end

      def find_color name
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
          one = @colors[rand @colors.length]
          two = @colors[rand @colors.length]
          response.push(one[:id])
          message += "\u0003" + one[:id].to_s + two[:color] + " "
        end
        return [message, response]
      end

      def etat m
        unless @users.empty?
          response = "État : "
          @users.each do |user|
            response += remove_hl(user[:nick]) + " : " + user[:etat].to_s + " | "
          end
          m.reply response[0..-4]
        end
      end

      def propre m
        unless @users.empty?
          response = "Propreté : "
          @users.each do |user|
            response += remove_hl(user[:nick]) + " " + user[:propre].to_s + " | "
          end
          m.reply response[0..-4]
        end
      end

      def restart_vote
        @vote = { data: 0, time: 0 }
      end

      def restart m
        restart_vote
        @users = []
        @memory = []
        m.channel.users.each do |user|
          add_nick user[0].nick unless user[0].nick == "Cubis"
        end
      end

      def anwser m
        if m.channel == "#cubis" or m.user.nick == "Samy"
          sender = find_user m.user.nick, @users
          now = Time.now.to_i
          if sender.nil?
            add_nick m.user.nick
            sender = find_user m.user.nick, @users
          end
          sender[:last_activity] = now
          if m.message == '!etat'
            etat m
          elsif m.message =~ /^!sexe : ([fm])$/
            sender[:sexe] = $~[1]
            if sender[:sexe] == 'm'
              m.reply "C'est noté, monsieur"
            else
              m.reply "C'est noté, madame"
            end
          elsif m.message == '!propre'
            propre m
          elsif m.message == '!hide'
            @hide.delete sender
          elsif m.message == '!voterestart'
            critere = 60*5 # 5 minutes
            actifs = 0
            @users.each do |user|
              actifs += 1 if now - user[:last_activity] < critere
            end
            if @vote[:time] == 0 or (@vote[:time] != 0 and now - @vote[:time] > critere)
              if @vote[:time] != 0 and now - @vote[:time] > critere
                restart_vote
                m.reply "Le vote précédent a expiré"
              end
              m.reply "Il y a " + actifs.to_s + " actif" + ((actifs != 1) ? "s" : "") + ", il faut " + ((actifs + actifs%2 + 2*((actifs + 1)%2))/2).to_s + " voix pour redémarrer la game"
            end
            @vote[:data] += 1
            @vote[:time] = now
            if @vote[:data] > actifs/2
              m.reply "Le jeu redémarre !"
              restart m
            end
          elsif m.message == '!restart' and m.user.nick == "Samy"
            restart m
          # elsif m.message == "!replay" and sender[:propre] == 0
          #   r = quizz
          #   sender[:game] = r[1]
          #   m.reply r[0]
          # elsif m.message =~ /!play\s:\s(([^\s]+\s){9}[^\s]+)/ and sender[:propre] == 0
          #   res = []
          #   m.message.split(":")[1].split(" ").each do |color|
          #     res.push(find_color(color)[:id])
          #   end
          #   if res == sender[:game]
          #     sender[:propre] = 20
          #     m.reply remove_hl(sender[:nick]) + " est à nouveau propre"
          #   else
          #     m.reply "Try again"
          #   end
          elsif m.message =~ /^!water ([^\s]+)/
            u = find_user $~[1], @users

            if sender[:propre] == 0
              m.reply "Désolé " + remove_hl(sender[:nick]) + ", tu es tout pas propre, tu ne peux plus jouer :("
              return
            end

            if u == sender
              m.reply "Te faire boire de l'eau à toi même. Et puis quoi encore"
              return
            end

            if u.nil?
              m.reply "Ce pseudo n'existe pas..."
              return
            end

            if u[:propre] == 0
              if u[:sexe] == 'm'
                m.reply "Nope, " + remove_hl(u[:nick]) + " est tout cochon"
              else
                m.reply "Nope, " + remove_hl(u[:nick]) + " est toute cochonne"
              end
              return
            end

            if rand(6) == 0
              random = @users[rand @users.length]
              m.reply remove_hl(sender[:nick]) + ", tu ne peux pas boire avec " + remove_hl(u[:nick]) + ". " + remove_hl(random[:nick]) + " est en train de faire de la merde avec les gobelets"
              return
            end

            if now - sender[:drink_time] < @drink_time
              m.reply remove_hl(sender[:nick]) + ", attends encore " + (@drink_time - now + sender[:drink_time]).to_s + " secondes"
              if sender[:spam] == 5
                m.channel.kick m.user.nick, "Stop spam"
              end
              sender[:spam] += 1
              return
            end

            sender[:drink_time] = now
            u[:etat] -= 2
            u[:etat] = 0 if u[:etat] < 0
            sender[:etat] -= 1 unless sender[:etat] == 0
            sender[:spam] = 0

          elsif m.message =~ /^!buffalo ([^\s]+)/
            u = find_user $~[1], @users

            if sender[:propre] == 0
              m.reply "Désolé " + remove_hl(sender[:nick]) + ", tu es tout pas propre, tu ne peux plus jouer :("
              return
            end

            if u.nil?
              m.reply "Ce pseudo n'existe pas..."
              return
            end

            if u[:wait]
              m.reply "Non, " + remove_hl(u[:nick]) + " est déjà en train de vomir"
              return
            end

            if u[:propre] == 0
              if u[:sexe] == 'm'
                m.reply remove_hl(u[:nick]) + " est tout cochon, et tu compte le faire boire ?"
              else
                m.reply remove_hl(u[:nick]) + " est toute cochonne, et tu compte la faire boire ?"
              end
              return
            end

            if now - sender[:buf_time] < @buffalo_time
              m.reply remove_hl(sender[:nick]) + ", attends encore " + (@buffalo_time - now + sender[:buf_time]).to_s + " secondes"
              if sender[:spam] == 5
                m.channel.kick m.user.nick, "Stop spam"
              end
              sender[:spam] += 1
              return
            end

            sender[:buf_time] = now - sender[:etat]*3
            if rand(4 + u[:etat]*2) == 0
              m.reply "Pas de chance, " + remove_hl(u[:nick]) + " buvait de la bonne main. Tu bois !"
              u = sender
            end
            u[:etat] += 1
            # etat m

            if u[:etat] > 9
              m.reply "Oups, j'ai bugué... :("
              return
            end

            if rand(10 - u[:etat]) == 0
              if rand(4) == 0
                m.reply "Attention, " + remove_hl(u[:nick]) + " va vomir " + u[:etat].to_s + " verre" + ((u[:etat] != 1) ? "s" : "") + " dans " + @hide_time.to_s + " secondes. Gare à la fontaine !"
                @hide = Array.new @users
                u[:wait] = true
                sleep @hide_time
                u[:wait] = false
                victimes = Array.new(@hide.map { |user| if user[:propre] != 0; user; end }).compact
              else
                victimes = Array.new(@users.map { |user| if user[:propre] != 0; user; end }).compact
              end
              if victimes.empty?
                victime = u
              else
                victime = victimes[rand victimes.length]
              end
              if victime == u
                m.reply remove_hl(u[:nick]) + " a vomi " + u[:etat].to_s + " verre" + ((u[:etat] != 1) ? "s" : "") + " dans sa culotte :)"
              else
                m.reply @phrases[u[:etat] - 1].call(remove_hl(u[:nick]), remove_hl(victime[:nick]), u[:sexe])
                # m.reply remove_hl(u[:nick]) + " a vomi " + u[:etat].to_s + " verre" + ((u[:etat] != 1) ? "s" : "") + " sur " + remove_hl(victime[:nick]) + " :)"
              end
              if u[:etat] >= 2 and u[:etat] <= 5
                sender[:propre] += 1
              elsif u[:etat] > 6
                sender[:propre] += 2
              end
              sender[:propre] = 20 if sender[:propre] > 20

              u[:propre] -= u[:etat]/2
              u[:propre] = 0 if u[:propre] < 0
              victime[:propre] -= u[:etat]
              victime[:propre] = 0 if victime[:propre] < 0
              u[:etat] = 0
              # propre m
            end
            sender[:spam] = 0
          end
        end
      end

      def on_join m
        add_nick m.user.nick
      end

      def add_nick nick
        mem = find_user nick, @memory
        if mem.nil?
          @users.push({ nick: nick, etat: 0, propre: 20, buf_time: 0 , drink_time: 0, game: [], spam: 0, last_activity: 0, sexe: 'm', wait: false })
        else
          @users.push mem
        end
      end

      def on_part m, user
        save_nick m.user.nick
      end

      def save_nick nick
        user = find_user nick, @users
        @users.delete user
        mem = find_user nick, @memory
        @memory.delete mem
        @memory.push user
      end

      def drink_one drinker, victime, sexe
        if sexe == 'm'
          "Ce raoul de " + drinker + " a vomi 1 verre sur " + victime
        else
          "Cette princesse de " + drinker + " a vomi 1 verre sur " + victime
        end
      end

      def drink_two drinker, victime, sexe
        if sexe == 'm'
          "Ce p'tit joueur de " + drinker + " a vomi 2 verres de cidre sur " + victime
        else
          "Cette p'tite joueuse de " + drinker + " a vomi 2 verres de Vodka sur " + victime
        end
      end

      def drink_three drinker, victime, sexe
        if sexe == 'm'
          "Ah, " + drinker + " ce bon cochon. Il a gerbé 3 verres sur " + victime
        else
          "Ah, " + drinker + " cette bonne cochonne. Elle a gerbé 3 verres sur " + victime
        end
      end

      def drink_four drinker, victime, sexe
        drinker + " a régurgité 4 verres dans la face de " + victime
      end

      def drink_five drinker, victime, sexe
        if sexe == 'm'
          drinker + " a cru pouvoir tenir l'alcool. Il a vomi 5 verres sur " + victime
        else
          drinker + " a cru pouvoir tenir l'alcool. Elle a vomi 5 verres sur " + victime
        end
      end

      def drink_six drinker, victime, sexe
        drinker + " a dégueulé ses 6 verres sur " + victime
      end

      def drink_seven drinker, victime, sexe
        drinker + " a béger 7 verres sur " + victime + ". Hummm, la bonne soupe ♥"
      end

      def drink_eight drinker, victime, sexe
        "Oulà ! " + drinker + " a vidé ses tripes sur " + victime + ". Bim, 8 verres !"
      end

      def drink_nine drinker, victime, sexe
        if sexe == 'm'
          drinker + " a vomi ses 9 verres sur " + victime + " tout en faisant un limousin"
        else
          drinker + " a vomi ses 9 verres sur " + victime + " pendant un double-rotor :p"
        end
      end
    end
  end
end