## The code to make the hexSticker

library(tidyverse)
library(magick)
library(showtext)
library(cropcircles)
library(ggpath)
library(ggtext)
library(glue)

# https://commons.wikimedia.org/wiki/File:Magnifying_Glass_-_The_Noun_Project.svg
# Timothy Dilich, CC0, via Wikimedia Commons
magnifier <- magick::image_read("inst/magnifier.png")

font_add_google("Lato", "lato")
showtext_auto()
ft <- "lato"
txt <- "#300D49"

pkg_name <- "ididvar"

img_cropped <- hex_crop(
  images = magnifier,
  border_colour = txt,
  border_size = 24
)

ggplot() +
  geom_from_path(aes(0.5, 0.5, path = img_cropped)) +
  annotate("text", x = 0.5, y = 0.1, label = pkg_name, family = ft, size = 20, colour = "white",
           angle = 30, hjust = -0.1, fontface = "bold") +
  xlim(0, 1) +
  ylim(0, 1) +
  theme_void() +
  coord_fixed()

ggsave("inst/idid_hex.png", height = 2.4, width = 2.4)
