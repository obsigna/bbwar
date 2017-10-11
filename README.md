Warsaw da GAS/Diebold foi adotado pelo Banco do Brasil para macOS
=================================================================

Recebi uma mensagem do Banco do Brasil (4004-0001):

> BB: desde o dia 20/02, clientes que usam Mac ou Linux deverão instalar
> o componente Warsaw para acessar a conta BB na internet. Saiba mais em
> [bb.com.br/warsaw](http://bb.com.br/warsaw).

### What the fuck!? – \#%\$\^&\*@

Ahh não, finalmente chegou esta praga no Mac também, e sem escapo,
quando quero continuar com BB e acesso na conta online …

> … O que posso fazer é cuidar de mim\
> Quero ser feliz ao menos\
> Lembra que o plano era ficarmos bem? …\
> (Vento No Litoral Legião Urbana)

### Cuidar de mim

O começo é sempre a análise da ameaça. Baixei o [pacote de instalação de
Varsóvia](https://seg.bb.com.br/duvidas.html) (clicando em AQUI), e
inspecionei o conteúdo com o aplicativo
[unpkg](https://www.timdoug.com/unpkg/) do Tim Doug, para saber quais
arquivos, scripts e executáveis serão instalados aonde.

![](https://github.com/obsigna/bbwar/raw/master/unpkg%20varsóvia.png)

 

### Análise

![](https://github.com/obsigna/bbwar/raw/master/warsaw%20content.png)

1.  Os daemons e agents no Mac OS X (i.e. serviços) são controlados
    pelas property lists
    ([launchd.plist(5)](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html)) e
    o pacote de instalação leva duas dessas listas:\
     `/Library/LaunchDaemons/com.diebold.warsaw.plist`

        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist SYSTEM "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.diebold.warsaw</string>
            <key>Program</key>
            <string>/usr/local/bin/warsaw/core</string>
            <key>ProgramArguments</key>
            <array>
              <string>/usr/local/bin/warsaw/core</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
          </dict>
        </plist>

    `/Library/LaunchAgents/com.diebold.warsaw.user.plist`

        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist SYSTEM "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.diebold.warsaw.user</string>
            <key>LimitLoadToSessionType</key>
            <string>Aqua</string>
            <key>Program</key>
            <string>/usr/local/bin/warsaw/core</string>
            <key>ProgramArguments</key>
            <array>
              <string>/usr/local/bin/warsaw/core</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
          </dict>
        </plist>

2.  As duas property lists direcionarão o launchd a iniciar o mesmo
    executável `/usr/local/bin/warsaw/core`, uma vez como serviço do
    sistema (Daemon) e uma vez como serviço em nome do usuário (Agent).
    E é bem claro que é o `core` qual preciso a atenção especial.
3.  Além disso, na hora de instalação será executado o programa certutil
    no diretório `/tmp`. Foi revelado que neste instante dois
    certificados serão instalados no sistema, o Warsaw Personal CA
    (certificado raiz auto-assinado) e o certificado 127.0.0.1 (emitido
    por Warsaw Personal CA). E após a instalação dos certificados, todo
    o conteúdo do diretório `/tmp` estará em disposição a apagar no
    re-inicio próximo do computador. Então este parte, não o `certutil`
    nem os certificados deixariam o sistema em risco – quando é
    garantido que o `certutil` é da fonte confiável. O programa não é
    assinado pelo um Certificado dos Desenvolvedores da Apple e o macOS
    não pode controlar a confiabilidade do executável.
4.  Nos diretórios `/usr/local/etc/warsaw` e `/usr/local/lib/warsaw`
    serão armazenadas arquivos de configuração em bibliotecas com
    subrotinas de ligação dinâmica e somente para utilização pelo tal
    `core`, e em-si não colocariam o sistema em risco.
5.  O arquivo `safari_refresh.html` é interessante porque o código de
    html explica como Warsaw funciona `/tmp/safari_refresh.html`

        <html>
        <body>
        <iframe src="https://127.0.0.1:30900" onload="setTimeout(function(){location='http://www.apple.com';}, 1000)" style="position: absolute;left: -5000px;"> </iframe>
        </body>
        </html>

    Então, o `core` providencia um HTTPS listen-socket no endereço local
    127.0.0.1 na porta 30900. O qual poderia ser acessada com um IFRAME
    do site do Banco e provavelmente assim o certificado de autorização
    seria informado para o servidor do banco.

### Segurança

A segurança é sujeito do ponto de vista. Tenho certeza que o BB cuida
bem a segurança no lado dele, e por isto desconsidero este lado nesse
discurso. ***O que posso fazer é cuidar de mim*** e aliviar as
minhas preocupações ou seja:

-   Tenho a ideia sobre o funcionamento desejado do
    `/usr/local/bin/core` do Warsaw, e até ai é tudo bem para mim.
    Contudo, ninguém garantiu sob pena de morte, que não existem outros
    funções escondidos no `core`, p.ex. para fins de espionagem.
-   Em acordo do ponto 5 da analise, o `core` pode ser acessado pelo
    servidor por meio de um web socket, e não estou contente que este
    função está restrito somente para o servidor do Banco. Quem garante
    que não sites fraudulentos quaisquers teriam um acesso também? E
    quanto os IFRAMES nos e-mails?

### Resumo

Acho melhor, que o Warsaw está ativo somente quando quero entra na minha
conta do BB, e então criei um script para desativar/ativar o Warsaw sob
demanda: `~/bin/bbwar.sh`

    #!/bin/sh

    if [ "$1" == "start" ]; then
       sudo launchctl load -F /Library/LaunchDaemons/com.diebold.warsaw.plist
            launchctl load -F /Library/LaunchAgents/com.diebold.warsaw.user.plist
    elif [ "$1" == "stop" ]; then
            launchctl unload -w /Library/LaunchAgents/com.diebold.warsaw.user.plist
       sudo launchctl unload -w /Library/LaunchDaemons/com.diebold.warsaw.plist
    fi

### Instalação

    mkdir -p ~/bin
    cp bbwar.sh ~/bin
    chmod +x ~bin/bbwar.sh


### Testes

    $ bbwar.sh stop
    $ ps axj | grep warsaw
    >>>>
    rolf              295   290   294      0    2 S+   s000    0:00.00 grep warsaw

    $ bbwar.sh start
    $ ps axj | grep warsaw
    >>>>
    root              354     1   354      0    0 Ss     ??    0:00.25 /usr/local/bin/warsaw/core
    rolf              356   201   356      0    1 S      ??    0:00.57 /usr/local/bin/warsaw/core
    rolf              358   290   357      0    2 R+   s000    0:00.00 grep warsaw


### O lado positivo

Não mais preciso Java no meu Mac, porque com a introdução do Warsaw, o
Banco do Brasil abandonou o Java. O acesso está bem mais rápido, e com o
meu script estou agora mais contente com a praginha Warsaw em comparação
do praga gigante chamada Java.
