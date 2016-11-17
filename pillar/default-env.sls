ssh_authorized_keys:
  # you can put your ssh keys here, this is also used by cloud-init
  # - "ssh-rsa and some long glibberish somebody@somewhere"
ssh_deprecated_keys:
  # you can copy deprecated keys here,
  # state.highstate will remove these old keys from users
meta:
  #
  encrypt: Your gpg public key
appliance:
  # standby: true # optional, if set appliance will not activate
  domain: localhost
  allowed_hosts: localhost testecs
  ssl:
    letsencrypt:
      # use snakeoil certs, because eg. 443 is behind ssh tunneling
      enabled: false
      additional_hosts: false
    client_certs_mandatory: true
    # if true, always need a client certificate
    # key: filename-key.pem # optional, if set ssl key for https host will be used
    # cert: filename-cert.pem # optional, if set ssl key for https host will be used
  storage:
    # setup: | # optional, will be executed if volatile or data can not be found
    # ignore_(volatile|data) # optional, if set, will not look for ecs-volatile or ecs-data filesystem
    ignore:
      volatile: true
      data: true
  # # set to your sentry url, must be the same as ecs_settings: SENTRY_DSN
  # sentry_dsn: 'https://url'
  backup:
    url: ssh://app@localhost/volatile/ecs-backup-test/
    encrypt: |
        -----BEGIN PGP PRIVATE KEY BLOCK-----
        Version: GnuPG v1

        lQOYBFgj284BCADhEvUgeeimNrWFEAiX3KvJmT74tvi2DnqtTLIEvRQBrI2vrnhg
        SWDslB2grWVWEPqE3cZB2RfiDr2SHCZgEV9IPkg+OBTHqJ/N51Gzj/1pMXTXXxcQ
        sPsfNZaIPXIJo5H+xyNvP6k8cKvlIYWI8LCWE1EGbvs21TkQIrmCCMWuB6YO/hYs
        CX2RuDzqtz2NK7QUG0tSehgVVwW9u4A4EzaEGghe9z5HQotGWgAS5hDRshI7iIeL
        MkgX8S9JXKoeDLmZopHNHhgCbquxRLmjg59E19shvaXrsEFNQNjQWdvYpYzUqzYD
        tK2x/WwafjkZWOnvN5JhK+0W/JXkTYtsI+e9ABEBAAEAB/oC4mGPGQjYDz9Sjtx+
        IVDEdijv4OmW7OB54o/G23gLanKGLXpZvFVlF4o528CYWQJ0DyLoh2q7L3ASx7be
        yDI1177iXAkfvH02kzzBWPqVuissMsnpB8xicsC0vibW0UhzoNbHKPEKaksFoweW
        GoS4AG2rVnynj/vZq7w/wP/suKKCtfEUXBhEUx8rB9U+1WBHhUR/yWToM1hQpxn4
        jTQE6w0Q6xbFAm9fdL1zoO6oHBOQe5KcowGnpjIFgCDE/B8RjekfqsIoJxrkhWke
        87ncmiMk+khldAcxqYkmQWQQabtnVZ5jCVI0D4TVf5FzZZuEQsnbyOrLUcr7aFZx
        tA3JBADjqJCLVe+xoGVUFui5HJizgAnm3B6KlB96fmoHMVc6X8R+sLVjvkDZgjiK
        d5gU2ZBbkU/aOUGlvUA6cHGsDiFGnmb4uz+cWA4a5u9o2CqNaONpzWLMmJ0PmROc
        gS1XvDyaClLzEiqYkpurrPLahcf+wMLwHd1sWYdow/NTuWg8qQQA/RgHR4hN4bNb
        sL2OBofDobxdlyrPmSZ83qFrGcFKMM7EGXjOYK9xSwPo2kgj8HcEQs0sKn1yaYzN
        jqDgqxZWwjnNfV5p9bICXQ4XynU5Fx+7J0zg6kLlo+QVs0BVEN+8yHYtnHdtcrjV
        uH9YVAZy58b0IfGAWMR48LYtykGxSvUEANkW7hzSB20ZhZJDcyhRewBqwL5h6/zD
        3yAJB8m1oPlrgEd37SX8eM2/ft9HBOyM1Ei5OLu/55cM9QQh+sZSvPz2GIrmdtda
        vknwTGREDPMRDhJ46fm13oU4kFZHv7hSSPg9kg2HanIkO5adEkhEVBL1vr7GPNDR
        tiRcURHt56YwPry0CmVjc19iYWNrdXCJATgEEwECACIFAlgj284CGy8GCwkIBwMC
        BhUIAgkKCwQWAgMBAh4BAheAAAoJEIp/e7BqphvsmpwIANUm39gF2/PwTHGQbv4v
        0U67wdAKfhDKWpvvdvg44cYud5ydglcf5PqXzMnnLLsOTRvyjVHtCyF4I6sCEST6
        6P5aceP/VIL6+J8H/1p1+3jv0/2xV8lnM2P1lRh6I11apZTzFb33lW2qsKIj9HrX
        Bwuhu6aMztYzVR1kqL5ZDUdno+OID3PhHevBTOIvAOlLkVV9XddWnJAk1bq5A4aO
        UGrC209mlORHmmj/VmmzQNlH9x208eS3S10iZpn9S65h40XJWbf6vYMm2qmXo3Ug
        jFzLXf5X8h8Yoc77c4LCGBVmkSqI8M62D22KYUcJFgzWWAQUlsxRAOL7Thiid+kj
        5tQ=
        =ix16
        -----END PGP PRIVATE KEY BLOCK-----
ecs:
  migrate:
    auto: true
  userswitcher:
    enabled: true
    parameter: -it
  settings: |
      DOMAIN = 'localhost'
      ABSOLUTE_URL_PREFIX = 'https://{}'.format(DOMAIN)
      ALLOWED_HOSTS = [DOMAIN, 'testecs']
      PDFAS_SERVICE = ABSOLUTE_URL_PREFIX+ '/pdf-as-web/'
      SECURE_PROXY_SSL = True
      CLIENT_CERTS_REQUIRED = True
      DEBUG = False

      # SENTRY_DSN = 'https://url' # set to sentry url if available
      # target EC
      ETHICS_COMMISSION_UUID = 'ecececececececececececececececec'

      SECRET_KEY = 'ptn5xj+85fvd=d4u@i1-($z*otufbvlk%x1vflb&!5k94f$i3w'
      REGISTRATION_SECRET = '!brihi7#cxrd^twvj$r=398mdp4neo$xa-rm7b!8w1jfa@7zu_'
      PASSWORD_RESET_SECRET = 'j2obdvrb-hm$$x949k*f5gk_2$1x%2etxhd!$+*^qs8$4ra3=a'

      EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
      EMAIL_BACKEND_UNFILTERED = 'django.core.mail.backends.console.EmailBackend'
      EMAIL_UNFILTERED_DOMAINS = () # = ('example.com', 'shoddy.technology')

      SMTPD_CONFIG['listen_addr'] = ('0.0.0.0', 8025)
      SMTPD_CONFIG['domain'] = DOMAIN

      # EMAIL_BACKEND = all emails except EMAIL_BACKEND_UNFILTERED
      # EMAIL_BACKEND_UNFILTERED = only registration/forgot-password/client-cert & UNFILTERED_DOMAINS
      # do not sent email but log to console: django.core.mail.backends.console.EmailBackend
      # send via EMAIL_* smtp settings: django.core.mail.backends.smtp.EmailBackend

  vault_encrypt: |
      -----BEGIN PGP PRIVATE KEY BLOCK-----
      Version: GnuPG v1

      lQOYBE3kIS0BCADHNBytxcTEasGbcT0ybEtCjbgUy8ePRaoDXaSo7W6/val+Gl3X
      AwbHAbAYNOO3Kr/4zvaX2qc3n8+AnsNNKnZDvYFEGsMzE80oVEwJMpoqH18mtnav
      Px63pFLyHeyUtYagmh+L0795zZxBe+a2Zl7K17klcx350iAai1Y4pHoJSUZ6X8/i
      VuKvNyfLh2DRb4JYYHM/bCGuu6z767gwDYkzJkk1n/u1Brr+LC3uwKSI1lvy3Tlx
      RSpurirTZN8av4RaLl+7A2EbxQQA+/kTXQZAdRmytMyAi2GceB+qFgvK4JFrl2DH
      /ElfMRJnKNguYCt0cW5GdGFqqykRVqwLak8jABEBAAEAB/4rQFvXuSCLexh1XSVp
      7Mx8c1PcJBC8wWX0HCFz0jWhKReDe0sTs6MFk469+sHUk9IhviIZf46eC7NcnFwQ
      RZ9u/tbxyBPI48xALOljd9q0OaKJv8VOMJjFS8b8rdWfxjgoZ75guEWTNzrtlu7V
      fK2pQiR/hpqkEuUIjmdWnhOnLyEGI4T7appy41fE1WApZRrzLr9xG3JZecXfPdGr
      S908BfStVaYPjg6i+vhxPeUaI51V1ARRkw6LiTw/A5rHGO+8SPZ4ZL/dI2AKlgcY
      kjfzKF728StCBRos65l4KF5HIGAfsWsOsbN2OEyoPQzXKl6my4sV74P6+TJlMQvg
      qTN9BADVOYB7JE4hRIiSp+gkuWlh6OiioRjAbxX67TfNoOzRW1MieGlhDAEGhsBI
      fEcpH9N89dCS162S7CRRaRf7XQmWqp3j1oM4AaW1eKmP7vr3vJW+FSMV0sDHEiOU
      Mk3sRJh16EF1PB1HK7lL8o+x+kvn61etdd+Q4TKAGIT+bpyCzwQA7yqJOZPO6uUI
      OAibMiYo7sRDmngB35TU2iZP8WlYtsQBKL+1ScdqZV6JzGHWAvPFMvYnEU+LVoQ5
      fQKRcDNW8KjHPktwo4yluxJYllebLVXow821zK2ffoTv42b7Mz4XQgoBRNd2uyzA
      qsjxwKHtWl80nZbUO9D4+QYkbPMq020D/3gcE98vgnu0FYJB/7GtizybpG97/Xsw
      1iAuBl+A9rQM0m+L6vNPyb1TIj3qeYi6vSG8C65NMV/qXfb8kuryephpClRSg8ev
      l3I/mMZ8FA19NktA0QKizKU3Ort6tXmNn8/EihOSPZjILg7ZEjY0KsFWRERk2fh7
      XkJrRIJfbbQoPfW0D2Vjc19tZWRpYXNlcnZlcokBOAQTAQIAIgUCTeQhLQIbLwYL
      CQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQMU/68+TVSpxkVAf/baQ8afYMdua/
      s7UNj/d8ugOW/TpksaA7LCvcV7MYFEYStIot9juvcBkuQNIFTiBo69GUnl63WBT5
      D4jyychLtnIKBiWbAvRLE4Tcb6/Zluu4XsrjXmZZlQoz1fo7SGveFabJ1D72LxXe
      789Du7TnFDAMTSQil/nLeShogfQLdWRpdNajHCIgJeB3+NByjeJpNHTFJTI6JcKN
      MSJ8UXoRy47bbodzUmaEgl2sCBdXEsTfm3eK34IdCzR7fj64/7S7U7y2KL2NFaFY
      XcgsooRQ7FAwIYeZWxruQPaypgWnuR2f0iTbAzfZ7i68WjZjMUpD9EfJIc/eKYvL
      iEeHU7SxQA==
      =qL2O
      -----END PGP PRIVATE KEY BLOCK-----
  vault_sign: |
      -----BEGIN PGP PRIVATE KEY BLOCK-----
      Version: GnuPG v1

      lQOYBE3kIQABCACsH2oUgCb8SHIqPx3aEn2pS+DStTMO01eZkoUH+NdY+h7egYN1
      SCebY4fYMwqayf9dP/eRBm+QI3/lJeuaxxa3uIjkO+4ENsgj4CH5ZeVR605U8CAo
      ZhI01ezv/AwWB5ZvljgTOeNA/BlUQSyATrBVITk1yIXH6izBA6T1mD0Or/NtBYVE
      vo42MSiPBQMBkMSM9aWZKNl6gJqy0j8tI3VWgnCoGNeAJL3RH7y8I4V1x5XRCZna
      N1CQc2bMvaaBsz0w6HUJ6ETEJEQmWSCqJsN76VG8UhkQ/leN7tPydGozTPMGIT7x
      ebtoEyvd3A4D+FFAoEiW/bUSgKRa70qzchzPABEBAAEAB/wLNORoP0vKg0EDpSZh
      a3DJFAqoTWnsnjAG7LZCpZ4Hygk2fYI8oZ0KjflrRy96kopQ3PhWde/Pl7AdEFH9
      utas0ZQAIDLIDXUMeOxdW5gJtGNePmApoTOwQvlxSpzS1l2iGErAXbWBJqjThobK
      N9VdRZN+//ZN5N5TFtSntOjMyuaU1pCqOiVsNMGSqYjYAdl+a91s4ZvtCwDTKrob
      UQ4jbcS7UjSbcfMqmqr8kjJMZ7btQ4znfIT1FNMeoWXSXBQW+2siWPbe09wcnAvD
      +vGImWVe2+b66bHV6nVo2JTsMANe4MQckAQGBZ25tRZWpNFMH5UqHLDVX+pKsc/K
      dzCxBADHg6tuPMPrEOAe1eiIglq4V8YxajSTGxxXDQzFQqKAuHDUhslEHFsEAqFO
      uN7ciGahCTzPOaA6c0QJJeYklqAZ5qILcMiN763wXOXtKAn+eCdj104G5FLkkVvH
      YoHyOZw7XjrSSpffXOGKS7sKa8gHIX8AHdrJUaFYu/m/mZMV5wQA3Np224c9jZYY
      1ewKcxXB/Je8c7f7PvQ+iP3ub8YyZPWq42YwcUX/NHa7DK+frjsSZwNJZEXpbu5X
      fZoXftAkkcxBIDznubjhbC1F0n6Htd0BOeSzFkPoTKxIdJNtabXW5qODIf982i5+
      I+vVTBW/3KI6GphXuFVgL3JRAdCtlNkD/2VONaONrbondrMPNn3KVeHt/jXxhzvb
      /dWxkEcgbOvs57VXFKhrr744LtQ4D5p0SrlkloidKDNByR+EoglCFbwD8JQa0mz3
      qgxsnyqBzgycd3KyNi5qUfVx9QCwNe0H7pGP40/Wr6ZzK2ZEc0qVI8tzrKhZ52rn
      xwlSz5PCmkLRRq+0DWVjc19hdXRob3JpdHmJATgEEwECACIFAk3kIQACGy8GCwkI
      BwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJELMEqSzEuXwj2bQH/2R/Cos4s12D7Iq5
      xmFXWJyAqF0nX79LrQ7nJqATx79qEAY3eMuqgGHFGRLUUcuZ+wMaW+1U4TXX5EEV
      R543QAmvwVHDtsZGSIm57Gu0bqHtSJUUWycfkkHmX/e7RS+tIUCtooNS+QvAPug5
      MnwcqLJIFXnjRbBUJBN9Ke0Tymi0PjgXuwUunf1pAPH2qcvLgP0q88613RQwx5UI
      SH1GkLHNQZAVwXqHhwL/ZX7hdnKqoOb6RMxsa6b4ynS/xbIqy/KTUmChZMEM9cJF
      fDEUuq+he1teTnpoAGhrlGnQCRcEvbXZ2jwOz8a7y++4xl8fOiH0XZwCi38QxVRs
      fUJ7VCc=
      =KKoR
      -----END PGP PRIVATE KEY BLOCK-----
