library(httr)
library(sqldf)
library(ggplot2)
library(readr)

#Create access token
clientID = read_file('clientID.txt')
secret = read_file('secret.txt')

response = POST(
  'https://accounts.spotify.com/api/token',
  accept_json(),
  authenticate(clientID, secret),
  body = list(grant_type = 'client_credentials'),
  encode = 'form',
  verbose()
)
mytoken = content(response)$access_token
HeaderValue = paste0('Bearer ', mytoken)



#Grab playlist
playlistID = '6eynr8gGFXVL2Cm0wmTH0V'
URI = paste0('https://api.spotify.com/v1/playlists/', playlistID)
response = GET(url = URI,add_headers(Authorization = HeaderValue))
playlist = content(response)



#Initalize dataframe
ntracks = length(playlist$tracks$items)
tracks_list<-data.frame(
  name=character(ntracks),
  id=character(ntracks),
  artist=character(ntracks),
  disc_number=numeric(ntracks),
  track_number=numeric(ntracks),
  duration_ms=numeric(ntracks),
  added_at=character(ntracks),
  stringsAsFactors=FALSE
)

#Add track items to dataframe
for(i in 1:ntracks){
  tracks_list[i,]$id <- playlist$tracks$items[[i]]$track$id
  tracks_list[i,]$name <- playlist$tracks$items[[i]]$track$name
  tracks_list[i,]$artist <- playlist$tracks$items[[i]]$track$artists[[1]]$name
  tracks_list[i,]$disc_number <- playlist$tracks$items[[i]]$track$disc_number
  tracks_list[i,]$track_number <- playlist$tracks$items[[i]]$track$track_number
  tracks_list[i,]$duration_ms <- playlist$tracks$items[[i]]$track$duration_ms
  tracks_list[i,]$added_at <- substr(playlist$tracks$items[[i]]$added_at,1,10)
}

# Get Additional Track Details
for(i in 1:nrow(tracks_list)){
  Sys.sleep(0.10)
  track_URI2 = paste0('https://api.spotify.com/v1/audio-features/',   
                      tracks_list$id[i])
  track_response2 = GET(url = track_URI2, 
                        add_headers(Authorization = HeaderValue))
  tracks2 = content(track_response2)
  
  tracks_list$key[i] <- tracks2$key
  tracks_list$mode[i] <- tracks2$mode
  tracks_list$time_signature[i] <- tracks2$time_signature
  tracks_list$acousticness[i] <- tracks2$acousticness
  tracks_list$danceability[i] <- tracks2$danceability
  tracks_list$energy[i] <- tracks2$energy
  tracks_list$instrumentalness[i] <- tracks2$instrumentalness
  tracks_list$liveliness[i] <- tracks2$liveness
  tracks_list$loudness[i] <- tracks2$loudness
  tracks_list$speechiness[i] <- tracks2$speechiness
  tracks_list$valence[i] <- tracks2$valence
  tracks_list$tempo[i] <- tracks2$tempo
}

#Plot energy and valence
ggplot(tracks_list,aes(valence,energy))+geom_point()
