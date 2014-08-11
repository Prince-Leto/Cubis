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
        @buffalo_time = 30 # Temps de rechargement de !buffalo
        @drink_time = 60 # Temps de rechargement de !water
        @double_buf_time = 3*60 # Durée du double buffalo
        @protection_time = 2*60 # Durée de la protection
        @bonus = 10 # Nombre de secondes bonus
        @bonus_time = 3*60 # Durée du bonus
        @vote_time = 60*5 # Durée d'activité des joueurs et du vote
        @game = []
        @hide = []
        @users = []
        @memory = []
        @colors = [{ id: 2, color: "bleu" }, { id: 3, color: "vert" }, { id: 5, color: "rouge" }, { id: 7, color: "jaune" }]
        @phrases = [method(:drink_one), method(:drink_two), method(:drink_three), method(:drink_four), method(:drink_five), method(:drink_six), method(:drink_seven), method(:drink_eight), method(:drink_nine)]
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

      def restart m
        @users = []
        @memory = []
        m.channel.users.each do |user|
          add_nick user[0].nick unless user[0].nick == "Cubis"
        end
      end

      def anwser m
        if m.channel != "#cubis" and m.user.nick != "Samy"
          return
        end

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
        elsif m.message =~ /!score ([^\s]+)/
          u = find_user $~[1], @users

          if u.nil?
            m.repply "Ce pseudo n'existe pas..."
            return
          end

          m.reply remove_hl(u[:nick]) + " : " + u[:vomi].to_s + " vomi" + ((u[:vomi] != 1) ? "s" : "") + " | " + (u[:verres].to_f/u[:vomi]).to_s + " verres par vomi en moyenne"
        elsif m.message == '!propre'
          propre m
        elsif m.message == '!hide'
          @hide.delete sender
        elsif m.message == '!voterestart'
          sender[:vote] = now
          actifs = 0
          vote = 0
          @users.each do |user|
            actifs += 1 if now - user[:last_activity] < @vote_time
            vote += 1 if now - user[:vote] < @vote_time
          end

          if vote > actifs/2
            m.reply "Le jeu redémarre !"
            restart m
          else
            m.reply "Il y a " + actifs.to_s + " actif" + ((actifs != 1) ? "s" : "") + ", il faut " + ((actifs + 2)/2).to_s + " voix pour redémarrer la partie"
          end
        elsif m.message == '!restart' and m.user.nick == "Samy"
          restart m
        # elsif m.message == "!replay" and sender[:propre] == 0
        #   r = quizz
        #   sender[:game] = r[1]
        #   m.reply r[0]
        elsif m.message =~ /!play\s:\s(([^\s]+\s){9}[^\s]+)/
          if sender[:propre] == 0
            m.reply "Désolé, " + remove_hl(sender[:nick]) + " tu es trop sale pour jouer."
            return
          end

          if @game.empty?
            m.reply "Trop tard, le jeu est fini :("
            return
          end

          res = []
          m.message.split(":")[1].split(" ").each do |color|
            res.push(find_color(color)[:id])
          end
          if res == @game
            @game = []
            r = rand(3)
            if r == 0
              sender[:double_buf] = now
             w m.reply "Bravo " + remove_hl(sender[:nick]) + " ! Tes buffalos comptent double pendant " + @double_buf_time.to_s + " secondes"
            elsif r == 1
              sender[:protection] = now
              m.reply "Bravo " + remove_hl(sender[:nick]) + " ! En récompense, tu ne peux pas te faire vomir dessus pendant " + @protection_time.to_s + " secondes"
            elsif r == 2
              sender[:bonus] = now
              m.reply "Bravo " + remove_hl(sender[:nick]) + " ! Tu as " + @bonus.to_s + " secondes d'attente en moins pendant " + @bonus_time.to_s + " secondes"
            end
          else
            m.reply "Try again"
          end
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

          if now - sender[:drink_time] < @drink_time
            m.reply remove_hl(sender[:nick]) + ", attends encore " + (@drink_time - now + sender[:drink_time]).to_s + " secondes"
            if sender[:spam] == 5
              m.channel.kick m.user.nick, "Stop spam"
            end
            sender[:spam] += 1
            return
          end

          if rand(6) == 0
            random = @users[rand @users.length]
            m.reply remove_hl(sender[:nick]) + ", tu ne peux pas boire avec " + remove_hl(u[:nick]) + ". " + remove_hl(random[:nick]) + " est en train de faire de la merde avec les gobelets"
          else
            u[:etat] -= 2
            u[:etat] = 0 if u[:etat] < 0
            sender[:etat] -= 1 unless sender[:etat] == 0
          end
          sender[:drink_time] = now - ((now - sender[:bonus] < @bonus_time) ? @bonus : 0)
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
              m.reply remove_hl(u[:nick]) + " est tout cochon, et tu comptes le faire boire ?"
            else
              m.reply remove_hl(u[:nick]) + " est toute cochonne, et tu comptes la faire boire ?"
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

          sender[:buf_time] = now - sender[:etat]*3 - ((now - sender[:bonus] < @bonus_time) ? @bonus : 0)
          if rand(4 + u[:etat]*2) == 0
            m.reply "Pas de chance, " + remove_hl(u[:nick]) + " buvait de la bonne main. Tu bois !"
            u = sender
          end

          u[:etat] += 1
          if now - sender[:double_buf] < @double_buf_time
            u[:etat] += 1
          end
          # etat m

          if rand(10 - u[:etat]) == 0 or u[:etat] > 9
            if rand(4) == 0
              hide_time = rand(7) + 4
              m.reply "\u0002Attention, " + remove_hl(u[:nick]) + " va vomir " + u[:etat].to_s + " verre" + ((u[:etat] != 1) ? "s" : "") + " dans " + hide_time.to_s + " secondes. Gare à la fontaine !"
              @hide = Array.new @users
              u[:wait] = true
              sleep hide_time
              u[:wait] = false
              victimes = Array.new(@hide.map { |user| if user[:propre] != 0 and now - user[:protection] > @protection_time; user; end }).compact
            else
              victimes = Array.new(@users.map { |user| if user[:propre] != 0 and now - user[:protection] > @protection_time; user; end }).compact
            end
            if victimes.empty?
              victime = u
            else
              victime = victimes[rand victimes.length]
            end
            if victime == u
              m.reply "\u0002" + remove_hl(u[:nick]) + " a vomi " + u[:etat].to_s + " verre" + ((u[:etat] != 1) ? "s" : "") + " dans sa culotte :)"
            else
              m.reply "\u0002" + @phrases[u[:etat] - 1].call(remove_hl(u[:nick]), remove_hl(victime[:nick]), u[:sexe])
            end
            if u[:etat] >= 2 and u[:etat] <= 5
              sender[:propre] += 1
            elsif u[:etat] >= 6
              sender[:propre] += 2
            end

            u[:vomi] += 1
            u[:verres] += u[:etat]
            u[:propre] -= u[:etat]/2
            u[:propre] = 0 if u[:propre] < 0
            victime[:propre] -= u[:etat]
            victime[:propre] = 0 if victime[:propre] < 0
            sender[:propre] = 20 if sender[:propre] > 20
            u[:etat] = 0
            # propre m
          end
          sender[:spam] = 0
        end

        if rand(100) == 0
          m.reply "Répondez vite, et profitez d'un bonus :"
          r = quizz
          @game = r[1]
          m.reply r[0]
        end
      end

      def on_join m
        add_nick m.user.nick
      end

      def add_nick nick
        mem = find_user nick, @memory
        if mem.nil?
          @users.push({ nick: nick, etat: 0, propre: 20, buf_time: 0 , drink_time: 0, spam: 0, last_activity: 0, sexe: 'm', wait: false, double_buf: 0, vote: 0, protection: 0, bonus: 0, vomi: 0, verres: 0 })
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
        drinker + " a régurgité 4 verres dans les cheveux de " + victime
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