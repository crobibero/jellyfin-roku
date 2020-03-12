sub Main()

  ' If the Rooibos files are included in deployment, run tests
  if (type(Rooibos__Init) = "Function") then Rooibos__Init()

  ' The main function that runs when the application is launched.
  m.screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  m.screen.setMessagePort(m.port)
  m.scene = m.screen.CreateScene("JFScene")
  m.screen.show()

  m.overhang = CreateObject("roSGNode", "JFOverhang")
  m.scene.insertChild(m.overhang, 0)
  
  m.page_size = 50

  app_start:
  m.overhang.title = ""
  ' First thing to do is validate the ability to use the API
  LoginFlow()

  ' load home page
  m.overhang.title = "Home"
  m.overhang.currentUser = m.user.Name
  group = CreateHomeGroup()
  m.scene.appendChild(group)

  m.scene.observeField("backPressed", m.port)
  m.scene.observeField("optionsPressed", m.port)
  m.scene.observeField("mutePressed", m.port)

  m.device = CreateObject("roDeviceInfo")
  m.device.SetMessagePort(m.port)

  ' This is the core logic loop. Mostly for transitioning between scenes
  ' This now only references m. fields so could be placed anywhere, in theory
  ' "group" is always "whats on the screen"
  ' m.scene's children is the "previous view" stack
  while(true)
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      print "CLOSING SCREEN"
      return
    else if isNodeEvent(msg, "backPressed")
      if msg.getRoSGNode().focusedChild <> invalid and msg.getRoSGNode().focusedChild.isSubtype("JFVideo")
        stopPlayback()
      end if
      ' Pop a group off the stack and expose what's below
      n = m.scene.getChildCount() - 1
      if n = 1
        ' Overhang + last scene... this is the end
        return
      end if
      m.scene.removeChildIndex(n)
      prevOptionsAvailable = group.optionsAvailable
      group = m.scene.getChild(n - 1)
      m.overhang.title = group.overhangTitle
      m.overhang.showOptions = group.optionsAvailable
      if group.optionsAvailable <> prevOptionsAvailable then
        if group.optionsAvailable = false then
          m.scene.unobserveField("optionsPressed")
        else
          m.scene.observeField("optionsPressed", m.port)
        end if
      end if
      m.overhang.visible = true
      if group.lastFocus <> invalid
        group.lastFocus.setFocus(true)
      else
        group.setFocus(true)
      end if
      group.visible = true
    else if isNodeEvent(msg, "optionsPressed")
      group.lastFocus = group.focusedChild
      panel = group.findNode("options")
      panel.visible = true
      panel.findNode("panelList").setFocus(true)
    else if isNodeEvent(msg, "closeSidePanel")
      if group.lastFocus <> invalid
        group.lastFocus.setFocus(true)
      else
        group.setFocus(true)
      end if
    else if isNodeEvent(msg, "homeSelection")
      ' If you select a library from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "homeRows")
      if node.type = "movies"
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false
        m.overhang.title = node.name
        group = CreateMovieListGroup(node)
        group.overhangTitle = node.name
        m.scene.appendChild(group)
      else if node.type = "tvshows"
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        m.overhang.title = node.name
        group = CreateSeriesListGroup(node)
        group.overhangTitle = node.name
        m.scene.appendChild(group)
      else if node.type = "boxsets"
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        m.overhang.title = node.name
        group = CreateCollectionsList(node)
        group.overhangTitle = node.name
        m.scene.appendChild(group)
      else if node.type = "Episode" then
        ' play episode
        ' todo: create an episode page to link here
        video_id = node.id
        video = CreateVideoPlayerGroup(video_id)
        if video <> invalid then
          group.lastFocus = group.focusedChild
          group.setFocus(false)
          group.visible = false
          group = video
          m.scene.appendChild(group)
          group.setFocus(true)
          group.control = "play"
          ReportPlayback(group, "start")
          m.overhang.visible = false
        end if
      else if node.type = "Movie" then
        ' open movie detail page
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        m.overhang.title = node.name
        m.overhang.showOptions = false
        m.scene.unobserveField("optionsPressed")
        group = CreateMovieDetailsGroup(node)
        group.overhangTitle = node.name
        m.scene.appendChild(group)
      else
        ' TODO - switch on more node types
        message_dialog("This library type is not yet implemented: " + node.type + ".")
      end if
    else if isNodeEvent(msg, "collectionSelected")
      node = getMsgPicker(msg, "picker")

      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = node.title
      group = CreateMovieListGroup(node)
      group.overhangTitle = node.title
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "movieSelected")
      ' If you select a movie from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")

      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = node.title
      m.overhang.showOptions = false
      m.scene.unobserveField("optionsPressed")
      group = CreateMovieDetailsGroup(node)
      group.overhangTitle = node.title
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "seriesSelected")
      ' If you select a TV Series from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")

      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = node.title
      m.overhang.showOptions = false
      m.scene.unobserveField("optionsPressed")
      group = CreateSeriesDetailsGroup(node)
      group.overhangTitle = node.title
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "seasonSelected")
      ' If you select a TV Season from ANYWHERE, follow this flow
      ptr = msg.getData()
      ' ptr is for [row, col] of selected item... but we only have 1 row
      series = msg.getRoSGNode()
      node = series.seasonData.items[ptr[1]]

      group.lastFocus = group.focusedChild.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = series.overhangTitle + " - " + node.title
      m.overhang.showOptions = false
      m.scene.unobserveField("optionsPressed")
      group = CreateSeasonDetailsGroup(series.itemContent, node)
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "episodeSelected")
      ' If you select a TV Episode from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")
      video_id = node.id
      video = CreateVideoPlayerGroup(video_id)
      if video <> invalid then
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false
        group = video
        m.scene.appendChild(group)
        group.setFocus(true)
        group.control = "play"
        ReportPlayback(group, "start")
        m.overhang.visible = false
      end if
    else if isNodeEvent(msg, "search_value")
      query = msg.getRoSGNode().search_value
      group.findNode("SearchBox").visible = false
      options = group.findNode("SearchSelect")
      options.visible = true
      options.setFocus(true)

      results = SearchMedia(query)
      options.itemData = results
      options.query = query
    else if isNodeEvent(msg, "pageSelected")
      group.pageNumber = msg.getRoSGNode().pageSelected
      if group.library = invalid
        ' Cover this case first to avoid "invalid.type" calls
      else if group.library.type = "movies"
        MovieLister(group, m.page_size)
      else if group.library.type = "boxsets"
        CollectionLister(group, m.page_size)
      else if group.library.type = "tvshows"
        SeriesLister(group, m.page_size)
      end if
      ' TODO - abstract away the "picker" node
      group.findNode("picker").setFocus(true)
    else if isNodeEvent(msg, "itemSelected")
      ' Search item selected
      node = getMsgPicker(msg)
      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      ' TODO - swap this based on target.mediatype
      ' types: [ Episode, Movie, Audio, Person, Studio, MusicArtist ]
      group = CreateMovieDetailsGroup(node)
      m.scene.appendChild(group)
      m.overhang.title = group.overhangTitle

    else if isNodeEvent(msg, "buttonSelected")
      ' If a button is selected, we have some determining to do
      btn = getButton(msg)
      if btn.id = "play-button"
        ' TODO - Do a better job of picking the last focus
        ' This is currently page layout Group, button Group, then button
        video_id = group.id
        video = CreateVideoPlayerGroup(video_id)
        if video <> invalid then
          group.lastFocus = group.focusedChild.focusedChild.focusedChild
          group.setFocus(false)
          group.visible = false
          group = video
          m.scene.appendChild(group)
          group.setFocus(true)
          group.control = "play"
          ReportPlayback(group, "start")
          m.overhang.visible = false
        end if
      else if btn.id = "watched-button"
        movie = group.itemContent
        if movie.watched
          UnmarkItemWatched(movie.id)
        else
          MarkItemWatched(movie.id)
        end if
        movie.watched = not movie.watched
      else if btn.id = "favorite-button"
        movie = group.itemContent
        if movie.favorite
          UnmarkItemFavorite(movie.id)
        else
          MarkItemFavorite(movie.id)
        end if
        movie.favorite = not movie.favorite
      end if
    else if isNodeEvent(msg, "optionSelected")
      button = msg.getRoSGNode()
      if button.id = "goto_search"
        ' Exit out of the side panel
        panel.visible = false
        if group.lastFocus <> invalid
          group.lastFocus.setFocus(true)
        else
          group.setFocus(true)
        end if
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        group = CreateSearchPage()
        m.scene.appendChild(group)
        m.overhang.title = group.overhangTitle
        group.findNode("SearchBox").findNode("search-input").setFocus(true)
        group.findNode("SearchBox").findNode("search-input").active = true
      else if button.id = "change_server"
        unset_setting("server")
        unset_setting("port")
        SignOut()
        wipe_groups()
        goto app_start
      else if button.id = "sign_out"
        SignOut()
        wipe_groups()
        goto app_start
      else if button.id = "add_user"
        unset_setting("active_user")
        unset_setting("server")
        unset_setting("port")
        wipe_groups()
        goto app_start
      end if
    else if isNodeEvent(msg, "position")
      video = msg.getRoSGNode()
      if video.position >= video.duration then
        video.control = "stop"
        video.state = "finished"
      end if
    else if isNodeEvent(msg, "fire")
      ReportPlayback(group, "update")
    else if isNodeEvent(msg, "state")
      node = msg.getRoSGNode()
      if node.state = "finished" then
        node.backPressed = "true"
      else if node.state = "playing" or node.state = "paused" then
        ReportPlayback(group, "update")
      end if
    else if type(msg) = "roDeviceInfoEvent" then
      event = msg.GetInfo()
      if event.appFocused <> invalid then
        child = m.scene.focusedChild
        if child <> invalid and child.isSubType("JFVideo") then
          child.systemOverlay = not event.appFocused
          if event.AppFocused = true then
            systemOverlayClosed()
          end if
        end if
      else if event.Mute <> invalid then
        m.mute = event.Mute
        child = m.scene.focusedChild
        if child <> invalid and child.isSubType("JFVideo") and child.systemOverlay = false then
        'Event will be called on caption change which includes the current mute status, but we do not want to call until the overlay is closed
          reviewSubtitleDisplay()
        end if
      else
        print "Unhandled roDeviceInfoEvent:"
        print msg.GetInfo()
      end if
    else
      print type(msg)
      print msg
    end if
  end while

end sub

sub LoginFlow()
  'Collect Jellyfin server and user information
  start_login:
  if get_setting("server") = invalid or ServerInfo() = invalid then
    print "Get server details"
    CreateServerGroup()
  end if

  if get_setting("active_user") = invalid then
    print "Get user login"
    CreateSigninGroup()
  end if

  m.user = AboutMe()
  if m.user = invalid or m.user.id <> get_setting("active_user")
    print "Login failed, restart flow"
    unset_setting("active_user")
    goto start_login
  end if

  wipe_groups()
end sub

sub RunScreenSaver()
  print "Starting screensaver..."
  screen = createObject("roSGScreen")
  m.port = createObject("roMessagePort")
  screen.setMessagePort(m.port)

  scene = screen.createScene("Screensaver")
  screen.Show()

  while(true)
    msg = wait(8000, m.port)
    if (msg <> invalid)
      msgType = type(msg)
      if msgType = "roSGScreenEvent"
        if msg.isScreenClosed() then return
      end if
    end if
  end while

end sub

sub wipe_groups()
  ' The 1 remaining child should be the overhang
  while(m.scene.getChildCount() > 1)
    m.scene.removeChildIndex(1)
  end while
end sub
