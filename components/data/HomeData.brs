sub setData()
    ' We keep json around just as a reference,
    ' but ideally everything should be going through one of the interfaces
    datum = m.top.json

    m.top.id = datum.id
    m.top.name = datum.name
    m.top.type = datum.type

    if datum.CollectionType = invalid
        m.top.CollectionType = datum.type
    else
        m.top.CollectionType = datum.CollectionType
    end if

    ' Set appropriate Images for Wide and Tall based on type

    if datum.type = "CollectionFolder" or datum.type = "UserView"
        params = { "maxHeight": 261, "maxWidth": 464 }
        m.top.thumbnailURL = ImageURL(datum.id, "Primary", params)
        m.top.widePosterUrl = m.top.thumbnailURL

        ' Add Icon URLs for display if there is no Poster
        if datum.CollectionType = "livetv"
            m.top.iconUrl = "pkg:/images/media_type_icons/live_tv_white.png"
        else if datum.CollectionType = "folders"
            m.top.iconUrl = "pkg:/images/media_type_icons/folder_white.png"
        end if

    else if datum.type = "Episode"
        imgParams = { "AddPlayedIndicator": datum.UserData.Played }

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        imgParams.Append({ "maxHeight": 261 })
        imgParams.Append({ "maxWidth": 464 })

        m.top.thumbnailURL = ImageURL(datum.SeriesId, "Primary", imgParams)

        ' Add Wide Poster  (Series Backdrop)
        if datum.ParentThumbImageTag <> invalid
            m.top.widePosterUrl = ImageURL(datum.ParentThumbItemId, "Thumb", imgParams)
        else if datum.ParentBackdropImageTags <> invalid
            m.top.widePosterUrl = ImageURL(datum.ParentBackdropItemId, "Backdrop", imgParams)
        else if datum.ImageTags.Primary <> invalid
            m.top.posterUrl = ImageURL(datum.SeriesId, "Primary", imgParams)
        end if

    else if datum.type = "Series"
        imgParams = { "maxHeight": 261 }
        imgParams.Append({ "maxWidth": 464 })

        if datum.UserData.UnplayedItemCount > 0
            imgParams["UnplayedCount"] = datum.UserData.UnplayedItemCount
        end if

        m.top.posterURL = ImageURL(datum.id, "Primary", imgParams)

        ' Add Wide Poster  (Series Backdrop)
        if datum.ImageTags <> invalid and datum.imageTags.Thumb <> invalid
            m.top.widePosterUrl = ImageURL(datum.Id, "Thumb", imgParams)
        else if datum.BackdropImageTags <> invalid
            m.top.widePosterUrl = ImageURL(datum.Id, "Backdrop", imgParams)
        end if

    else if datum.type = "Movie"
        imgParams = { AddPlayedIndicator: datum.UserData.Played }

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        imgParams.Append({ "maxHeight": 261 })
        imgParams.Append({ "maxWidth": 175 })

        m.top.posterURL = ImageURL(datum.id, "Primary", imgParams)

        ' For wide image, use backdrop
        imgParams["maxWidth"] = 464

        if datum.ImageTags <> invalid and datum.imageTags.Thumb <> invalid
            m.top.thumbnailUrl = ImageURL(datum.Id, "Thumb", imgParams)
        else if datum.BackdropImageTags <> invalid and datum.BackdropImageTags[0] <> invalid
            m.top.thumbnailUrl = ImageURL(datum.id, "Backdrop", imgParams)
        end if

    else if datum.type = "Video"
        imgParams = { AddPlayedIndicator: datum.UserData.Played }

        if datum.UserData.PlayedPercentage <> invalid
            imgParams.Append({ "PercentPlayed": datum.UserData.PlayedPercentage })
        end if

        imgParams.Append({ "maxHeight": 261 })
        imgParams.Append({ "maxWidth": 175 })

        m.top.posterURL = ImageURL(datum.id, "Primary", imgParams)

        ' For wide image, use backdrop
        imgParams["maxWidth"] = 464

        if datum.ImageTags <> invalid and datum.imageTags.Thumb <> invalid
            m.top.thumbnailUrl = ImageURL(datum.Id, "Thumb", imgParams)
        else if datum.BackdropImageTags[0] <> invalid
            m.top.thumbnailUrl = ImageURL(datum.id, "Backdrop", imgParams)
        end if
    else if datum.type = "MusicAlbum" or datum.type = "Audio" or datum.type = "Book"
        params = { "maxHeight": 261, "maxWidth": 261 }
        m.top.thumbnailURL = ImageURL(datum.id, "Primary", params)
        m.top.widePosterUrl = m.top.thumbnailURL
        m.top.posterUrl = m.top.thumbnailURL

    else if datum.type = "TvChannel" or datum.type = "Channel"
        params = { "maxHeight": 261, "maxWidth": 464 }
        m.top.thumbnailURL = ImageURL(datum.id, "Primary", params)
        m.top.widePosterUrl = m.top.thumbnailURL
        m.top.iconUrl = "pkg:/images/media_type_icons/live_tv_white.png"
    end if

end sub