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
        videoElement.className = "col-md-6"
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
      $("h1").text name
      $("#subTitle").text(location.href).addClass "alert alert-dismissable alert-warning"
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
      #unless window.location.href is "http://demo123.meteor.com/speak"
      $("#leave").css "display", "inline"
      $("#copy").css "display", "inline"
      $(".clock").TimeCircles time:
        Days:
          show: false

  Template.speak.events
    "click #copy": ->
      window.prompt "Share this url to anyone you want to connect:", window.location.href
