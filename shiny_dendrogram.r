# Load necessary libraries
library(shiny)
library(tidyverse)
library(ggdendro)

# Load custom color generation function
source("generate_colors.R")

# Data come from this publication:
# https://doi.org/10.3389/fmicb.2022.881535
df <- read.delim("yeast_metal_tolerances.tsv")
df <- df |> column_to_rownames("ORF")

# Perform hierarchical clustering
df_distances <- dist(df, method = "euclidean")
df_clusters <- stats::hclust(df_distances, method = "ward.D2")
df_dendrogram <- as.dendrogram(df_clusters)

# Extract dendrogram data for ggplot
dendro_df <- dendro_data(df_dendrogram)

# Function to create a zoomable dendrogram app
create_zoom_tree <- function() {
  # Define UI and server components
  ui <- fluidPage(
    titlePanel("Zoomable Dendrogram"),
    sidebarLayout(
      sidebarPanel(
        numericInput("cut_height", "Cut Height for Clusters:",
          value = 10, min = 0, max = 50, step = 1
        ),
        br(),
        textInput("search_label", "Search for label:",
          placeholder = "Enter row label"
        ),
        actionButton("zoom_to_label", "Zoom to Label", class = "btn-primary"),
        br(), br(),
        actionButton("reset_zoom", "Reset Zoom", class = "btn-secondary"),
        width = 3
      ),
      mainPanel(
        plotOutput("dendrogram",
          height = "800px",
          brush = brushOpts(id = "plot_brush", resetOnNew = TRUE),
          dblclick = "plot_dblclick"
        ),
        width = 9
      )
    )
  )

  server <- function(input, output, session) {
    # Reactive values for zoom
    ranges <- reactiveValues(x = NULL, y = NULL)

    output$dendrogram <- renderPlot({
      # Get cluster assignments at specified height
      clusters <- cutree(df_clusters, h = input$cut_height)

      # Add cluster colors to labels
      dendro_labels <- dendro_df$labels
      dendro_labels$cluster <- clusters[dendro_labels$label]
      dendro_labels$cluster <- as.factor(dendro_labels$cluster)

      # Find all segments that cross the cut height (create cluster boundaries)
      cluster_segments <- dendro_df$segments |>
        dplyr::filter((y <= input$cut_height & yend > input$cut_height) |
          (y > input$cut_height & yend <= input$cut_height)) |>
        mutate(cut_x = ifelse(y <= input$cut_height, x, xend)) |>
        arrange(cut_x)

      # Map intersection points to actual cluster numbers
      if (nrow(cluster_segments) > 0) {
        # For each intersection point, find the cluster it represents
        cluster_segments$cluster_num <- sapply(cluster_segments$cut_x, function(x_pos) {
          # Find the closest leaf to this x position
          closest_leaf <- dendro_labels[which.min(abs(dendro_labels$x - x_pos)), ]
          return(as.numeric(as.character(closest_leaf$cluster)))
        })
      }
      # Generate plot with segments and labels
      p <- ggplot() +
        geom_segment(
          data = dendro_df$segments,
          aes(x = y, y = x, xend = yend, yend = xend)
        ) +
        geom_text(
          data = dendro_labels,
          aes(x = y, y = x, label = label, color = cluster),
          hjust = 1.05, vjust = 0.5, angle = 0, size = 3, fontface = "bold", family = "sans"
        ) +
        geom_vline(xintercept = input$cut_height, linetype = "dashed", color = "red") +
        theme_minimal() +
        theme(
          axis.text.y = element_blank(),
          axis.text.x = element_text(color = "black", size = 12),
          axis.title.x = element_text(color = "black", size = 16),
          legend.text = element_text(size = 14),
          legend.title = element_text(size = 16),
          legend.key.size = unit(1.5, "cm"),
          plot.margin = margin(t = 20, r = 20, b = 20, l = 120, unit = "pt")
        ) +
        labs(title = paste("Brush to zoom. Cut height:", input$cut_height), y = "", x = "Cut height") +
        scale_color_manual(values = random_colors) +
        guides(color = guide_legend(override.aes = list(size = 10), ncol = 4)) +
        coord_cartesian(clip = "off")

      # Add cluster labels at intersection points
      if (nrow(cluster_segments) > 0) {
        p <- p + geom_text(
          data = cluster_segments,
          aes(y = cut_x, x = input$cut_height, label = cluster_num),
          size = 4, fontface = "bold", color = "red",
          hjust = 0.5, vjust = -0.5
        )
      }

      # Apply zoom if ranges are set
      if (!is.null(ranges$x)) {
        p <- p + xlim(ranges$x[1], ranges$x[2])
      }
      if (!is.null(ranges$y)) {
        p <- p + ylim(ranges$y[1], ranges$y[2])
      }
      p
    })

    # When a brush is made, update the zoom ranges
    observeEvent(input$plot_brush, {
      brush <- input$plot_brush
      if (!is.null(brush)) {
        ranges$x <- c(brush$xmin, brush$xmax)
        ranges$y <- c(brush$ymin, brush$ymax)
      }
    })

    # Function to zoom to a specific label
    observeEvent(input$zoom_to_label, {
      if (input$search_label != "") {
        # Find the label in dendro_labels
        label_match <- dendro_df$labels[dendro_df$labels$label == input$search_label, ]

        if (nrow(label_match) > 0) {
          # Set zoom range around the label
          label_x <- label_match$y[1] # Note: coordinates are swapped
          label_y <- label_match$x[1]

          # Create zoom window around the label
          zoom_width_x <- 20 # Adjust as needed
          zoom_width_y <- 30 # Adjust as needed

          ranges$x <- c(label_x - zoom_width_x, label_x + zoom_width_x)
          ranges$y <- c(label_y - zoom_width_y, label_y + zoom_width_y)
        } else {
          showNotification("Label not found!", type = "warning", duration = NULL, closeButton = TRUE)
        }
      }
    })

    # Reset zoom button
    observeEvent(input$reset_zoom, {
      ranges$x <- NULL
      ranges$y <- NULL
    })
  }

  shinyApp(ui, server)
}

# Run the app
create_zoom_tree()
