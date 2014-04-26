Router.configure
  layoutTemplate: 'layout'

Router.map ->
  @route 'welcome', path: '/'
  @route 'speak', path: 'speak'

if Meteor.isClient
  Template.speak.rendered ->
    #initialize webrtc
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
    webrtc.once 'readyTocall', ->
      webrtc.joinRoom room if room

    # add remtoe videos
    webrtc.on "videoAdded", (video, peer) ->
      remotes = document.getElementById("remotes")
      if remotes
        videoElement = document.createElement("div")
        videoElement.className = "col-md-6"
        videoElement.id = "container_" + webrtc.getDomId(peer)
        videoElement.appendChild video
        remotes.appendChild videoElement

    # remove remote videos if user quit the call
    webrtc.on "videoRemoved", (video, peer) ->
      remotes = document.getElementById("remotes")
      el = document.getElementById("container_" + webrtc.getDomId(peer))
      remotes.removeChild el  if remotes and el
