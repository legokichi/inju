# 手順
1. `node.js` をインストール。
1. 実行環境作成。`npm run init` と入力。
1. `getUserMedia` を使用するのに https が必須のため鍵を作成する
    `./ssl/certificate.pem` と `./ssl/private.pem` を作成。
    1. `mkdir ssl`
    1. `cd ssl`
    1. `openssl req -new -x509 -sha256 -newkey rsa:2048 -days 365 -nodes -out certificate.pem -keyout private.pem`
       ([参考](http://postd.cc/https-on-nginx-from-zero-to-a-plus-part-1/))
1. サーバを起動。`coffee server.coffee` と入力。
1. `https:/[サーバのIPアドレス]:8083/` にアクセス。
    * IPアドレス確認
        * mac: `ifconfig | grep 192`
        * windows: `ipconfig`
1. red green などの色のリンクを押して端末に色を割りあてる(確認のときの利便性のため。色無しでも動く)
