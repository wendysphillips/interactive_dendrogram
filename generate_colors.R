# Generate a very long vector of high visibility colors
z <- colors()

not_to_use <- c("gray", "grey", "white", "azure", "snow", "cornsilk", "beige", "aliceblue", "mintcream", "bisque", "gainsboro", "honeydew", "ivory", "lavender", "lemonchiffon",  "lightcyan", "linen", "mistyrose" ,"yellow", "oldlace", "papayawhip", "moccasin", "palegoldenrod","peachpuff" , "seashell", "wheat", "thistle")

for (cl in not_to_use){
  z <- z[grep(cl, z, invert = TRUE)]
}

set.seed(111)
random_colors <- sample(z, length(z), replace = FALSE)

     