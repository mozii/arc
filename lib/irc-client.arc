(def client (hostname port)
  ($ (call-with-values 
         (lambda () (tcp-connect ,hostname ,port))
       list)))

;; be nice to make this settable, so we could do (= (env "FOO") "bar")
(= env ($ getenv))

(= server* "localhost")

(def log args
  (w/appendfile o "irclog"
     (w/stdout o (apply prs args) (prn))))

(def out args
  (let args (join args (list "\r"))
    (apply prn args )
    (apply log "=>" args (list "\n")))
  nil)

(def parse (s)
  (let toks (fn (s) (let ts (tokens s)
                      (cons (map sym (tokens (car ts) #\!))
                            (map sym (cdr ts)))))
    (aif (findsubseq ":" s 1) 
         (join (toks (subseq s 0 it))
               (list (subseq s (+ it 1))))
         (toks s))))

(def irc (nick)
  (let (ip op)
    (client server* 6667)
    (w/stdin ip
      (w/stdout op
        (out "NICK " nick)
        (out
         "USER "          (or (env "USER") "unknown")
         " unknown-host " server*
         " :"             "arcbot"
         ", version "     "0")

        (whilet l (readline)
          (= l (trim (trim l 'end) 'front #\:))
          (log "<=" l)
          (let l (parse l)
            (case (caar l)
              NOTICE (log  "ooh, a notice:" (cdr l))
              PING   (out "PONG :" (cadr l))
              (case (cadr l)
                |001|    (map [out "JOIN " _]  (list "#fart" "#poop"))
                |433|    (do (log "Oh hell, gotta whop the nick.")
                             (irc (+ nick "_")))
                JOIN     (log "user" (car l) "joined" (car:cdr:cdr l))
                PRIVMSG  (withs ((speaker privmsg dest text) l
                                 toks (tokens text))
                                (when (headmatch nick (car toks))
                                  ;; TODO: beware of botwars.
                                  (out "PRIVMSG " dest " :" (car speaker) ", you like me!" )
                                  ))
                (log "?")))))))))