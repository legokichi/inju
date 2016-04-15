Ajax = window.duxca.lib.Ajax
SurfaceUtil = window.cuttlebone.SurfaceUtil
WebSocket = window.WebSocket

nmdmgr = null
named = null
image_cnv = null
depth_cnv = null
cursor_img = null
ws = null

reward = 0
endEpisode = false

setup = (next)->
  Promise.all([
    NarLoader.loadFromURL("./nar/first.nar"),
    #NarLoader.loadFromURL("./nar/mobilemaster.nar"),
    NarLoader.loadFromURL("./nar/origin.nar")
  ]).then ([shellNanikaDir, balloonNanikaDir])->
    shellDir = shellNanikaDir.getDirectory("shell/master").asArrayBuffer()
    balloonDir = balloonNanikaDir.asArrayBuffer()
    shell = new cuttlebone.Shell(shellDir)
    balloon = new cuttlebone.Balloon(balloonDir)
    Promise.all([
      shell.load(),
      balloon.load()
    ])
  .then ([shell, balloon])->
    window.nmdmgr = nmdmgr = new cuttlebone.NamedManager()
    document.body.appendChild(nmdmgr.element)
    hwnd = nmdmgr.materialize(shell, balloon)
    window.named = named = nmdmgr.named(hwnd)
    named.scope(0).surface(0)
    named.scope(1).surface(-1)
    named.on "mousemove", (ev)->
      surface = named.scope(0).surface()
      {top, left} = $(surface.element).offset()
      {offsetX, offsetY, scopeId, region} = ev
      $(cursor_img).css("top", top+offsetY)
      $(cursor_img).css("left", left+offsetX)
      console.log ev
      if /Bust/.test(region)
        named.scope(0).surface(25)
        reward += 1
      else if /Face/.test(region)
        named.scope(0).surface(7)
        reward -= 1

  .then ->
    image_cnv = $("#image")[0]
    depth_cnv = $("#depth")[0]
    surface = named.scope(0).surface()
    {top, left} = $(surface.element).offset()
    cursor_img = $("<img src='./cursor.png' />").css({"position": "absolute", top, left}).appendTo("body")[0]
  .then ->
    window.ws = ws = new WebSocket('ws://localhost:8765/ws')
    ws.binaryType = 'arraybuffer'
    ws.onerror = (err)-> throw err
    ws.onopen = ->
      console.log "open"
      next()
  .catch (err)-> setTimeout -> throw err

main = (next)->
  next()
  reward = 0
  named.scope(0).surface(0)
  surface = named.scope(0).surface()
  named.scope(0).blimp().clear()
  {top, left} = $(surface.element).offset()
  $(cursor_img).css({top, left})
  recur(0)

recur = (i)->
  sence ->
    if i > 30
    then setTimeout -> main ->endEpisode = true; console.log "step"
    else setTimeout -> recur(i+1)


sence = (next)->
  image_cnv.width = image_cnv.width
  surface = named.scope(0).surface()
  {top, left} = $(cursor_img).offset()
  {top:_top, left:_left} = $(surface.element).offset()
  ctx = image_cnv.getContext("2d")
  ctx.drawImage(surface.cnv, 0, 0)
  ctx.drawImage(cursor_img, left-_left, top-_top)
  Promise.all([
    Ajax.getArrayBuffer(image_cnv.toDataURL("image/png")),
    Ajax.getArrayBuffer(depth_cnv.toDataURL("image/png"))
  ]).then ([image_buf, depth_buf])->
    image_arr = Array.from(new Uint8Array(image_buf))
    depth_arr = Array.from(new Uint8Array(depth_buf))
    o =
      reward: reward #public float reward;
      endEpisode: endEpisode #public bool endEpisode;
      image: image_arr #public byte[] image;
      depth: depth_arr # public byte[] depth;
      hoge: [0,0,0] # データサイズの帳尻合わせ
    endEpisode = false
    pack = msgpack.encode(o)
    ws.send(pack.buffer)
    ws.onmessage = (ev)->
      console.log ev
      {top, left} = $(cursor_img).offset()
      switch (ev.data)
        when "0" then $(cursor_img).css("top", top+20)
        when "1" then $(cursor_img).css("left", left+20)
        when "2" then "stay here"
        else          console.warn(ev.data)
      surface = named.scope(0).surface()
      {top, left} = $(cursor_img).offset()
      {top:_top, left:_left} = $(surface.element).offset()
      ctx.drawImage(cursor_img, left-_left, top-_top)
      {isHit, name} = SurfaceUtil.getRegion(surface.cnv, surface.surfaceNode, left-_left, top-_top)
      console.log name
      if /Bust/.test(name)
        named.scope(0).surface(25)
        named.scope(0).blimp().talk("・・・")
        reward += 10
      else if /Face/.test(name)
        named.scope(0).surface(7)
        named.scope(0).blimp().talk("痛い！")
        reward -= 1
      next()




window.addEventListener "DOMContentLoaded", -> setup -> main -> console.log "init main";
window.addEventListener "error", (ev)->
  err = ev.error
  console.error err
  if err instanceof Error
    pre = $("<pre />")
    .append("<br>"+err)
    .append("<br>"+err.message)
    .append("<br>"+err.stack)
  else if Object::toString.call(err) is "[object Object]"
    pre = $("<pre />")
    .append("<br>"+JSON.stringify(err))
  else
    pre = $("<pre />")
    .append("<br>"+err)
  $("body")
  .css({"background-color": "gray"})
  .append(pre)

getImage = (url, cb)->
  img = new Image()
  img.src = url
  img.onload = cb
  img.onerror = (ev)-> throw ev
