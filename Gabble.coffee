@Messages  = new Meteor.Collection "messages"
Router.configure
  layoutTemplate: 'layout'
Router.map ->
  @route 'welcome', path: '/'
  @route 'speak', path: 'speak'

if Meteor.isClient
  Template.speak.rendered = ->
    # initialize webrtc
    room = location.search and location.search.split("?")[1]
    webrtc = new SimpleWebRTC(
      localVideoEl: "localVideo"
      remoteVideosEl: ""
      autoRequestMedia: true
      debug: false
      detectSpeakingEvents: true
      autoAdjustMic: false
    )
    #join room if room is available
    webrtc.once "readyToCall", ->
      webrtc.joinRoom room  if room

    # add remote videos
    webrtc.on "videoAdded", (video, peer) ->
      remotes = document.getElementById("remotes")
      if remotes
        videoElement = document.createElement("div")
        videoElement.className = "col-md-12 no-padding"
        videoElement.id = "container_" + webrtc.getDomId(peer)
        videoElement.appendChild video
        remotes.appendChild videoElement

    # remove remote videos if user quits the call
    webrtc.on "videoRemoved", (video, peer) ->
      remotes = document.getElementById("remotes")
      el = document.getElementById("container_" + webrtc.getDomId(peer))
      remotes.removeChild el  if remotes and el

    # prepare video-chat room
    setRoom = (name) ->
      $("form").remove()
      $("h1").remove()
      $("#subTitle").text(location.href).addClass "url"
      $("body").addClass "active"

    if room
      setRoom room
    else
      $("form").submit ->
        val = $("#sessionInput").val().toLowerCase().replace(/\s/g, "-").replace(/[^A-Za-z0-9_\-]/g, "")
        webrtc.createRoom val, (err, name) ->
          #console.log " create room cb", arguments_
          $("#leave").css "display", "inline"
          $("#copy").css "display", "inline"
          $("#chat-wrapper").css "display", "inline"
          $(".create-room").remove()
          chatDiv = document.getElementById("chat-box")
          chatDiv.scrollTop = chatDiv.scrollHeight
          $(".clock").TimeCircles time:
            Days:
              show: false

          newUrl = location.pathname + "?" + name
          unless err
            history.replaceState
              foo: "bar"
            , null, newUrl
            setRoom name
          else
            console.log err
        false

    unless window.location.href is "http://localhost:3000/speak"
    #unless window.location.href is "http://gabblev1.meteor.com/speak"
      $("#leave").css "display", "inline"
      $("#copy").css "display", "inline"
      $("#chat-wrapper").css "display", "inline"
      $(".create-room").remove()
      $(".clock").TimeCircles time:
        Days:
          show: false
    chatDiv = document.getElementById("chat-box")
    chatDiv.scrollTop = chatDiv.scrollHeight   
  Template.speak.events
    "click #copy": ->
      window.prompt "Share this url to anyone you want to connect:", window.location.href
      
  Template.chat.messages = ->
    room  = window.location.href
    Messages.find({room: room}, { sort: time: -1}).fetch()




  Template.chat.events
    'change #name': (e, t)->
      name = t.find '#name'
      $('#name').hide() if name.value isnt ''
      $('#message').focus()

    'keypress #message': (e, t)->
      if e.keyCode is 13 
        text = t.find "#message"
        name = t.find '#name'
        if name.value is ''
          alert "Please enter your name or alias"
          $('#name').focus()
        else
          room  = window.location.href
          Messages.insert({name: name.value, message: text.value, room: room })	if text.value isnt ''
          text.value = ''
        chatDiv = document.getElementById("chat-box")
        chatDiv.scrollTop = chatDiv.scrollHeight
    'click .btn': ->
      Meteor.call "removeAllMessages"

  Template.speak.config = ->
    (editor) ->
      # Set some reasonable options on the editor
      editor.setShowPrintMargin(false)
      editor.getSession().setUseWrapMode(true)

if Meteor.isServer
  Meteor.methods removeAllMessages: ->
    Messages.remove {}
