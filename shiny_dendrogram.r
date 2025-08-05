# Load necessary libraries
library(shiny)
library(dplyr)
library(tibble)
library(ggplot2)
library(ggdendro)

### CHANGE INPUT FILE HERE ###
df <- read.table("yeast_metal_tolerances.tsv", header = TRUE, row.names = 1)
# The first column should contain the items to be clustered
# The input table should be pre-processed with any chosen scaling prior to clustering
# The above data come from this publication:
# https://doi.org/10.3389/fmicb.2022.881535

# Load custom color generation function
source("generate_colors.R")

# Function to create a zoomable dendrogram app
create_zoom_tree <- function() {
  # Define UI and server components
  ui <- fluidPage(
    titlePanel("Zoomable Dendrogram"),
    sidebarLayout(
      sidebarPanel(
        selectInput("distance_method", "Distance Method:",
          choices = c("manhattan", "euclidean", "maximum", "binary"),
          selected = "manhattan"
        ),
        selectInput("cluster_method", "Clustering Method:",
          choices = c("complete", "single", "average", "ward.D2"),
          selected = "ward.D2"
        ),
        br(),
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
        br(), br(),
        downloadButton("download_clusters", "Export Cluster Data", class = "btn-success"),
        br(), br(),
        downloadButton("download_image", "Export Image (PNG)", class = "btn-info"),
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
    
    # Reactive clustering calculations
    df_clusters <- reactive({
      df_distances <- dist(df, method = input$distance_method)
      stats::hclust(df_distances, method = input$cluster_method)
    })
    
    # Reactive dendrogram data
    dendro_df <- reactive({
      df_dendrogram <- as.dendrogram(df_clusters())
      dendro_data(df_dendrogram)
    })

    output$dendrogram <- renderPlot({
      # Get cluster assignments at specified height
      clusters <- cutree(df_clusters(), h = input$cut_height)

      # Add cluster colors to labels
      dendro_labels <- dendro_df()$labels
      dendro_labels$cluster <- clusters[dendro_labels$label]
      dendro_labels$cluster <- as.factor(dendro_labels$cluster)

      # Find all segments that cross the cut height (create cluster boundaries)
      cluster_segments <- dendro_df()$segments |>
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
          data = dendro_df()$segments,
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
          legend.position = "none",
          plot.margin = margin(t = 20, r = 20, b = 20, l = 120, unit = "pt")
        ) +
        labs(title = paste("Distance:", input$distance_method, "| Clustering:", input$cluster_method, "| Cut height:", input$cut_height), y = "", x = "Cut height") +
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
        label_match <- dendro_df()$labels[dendro_df()$labels$label == input$search_label, ]

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
    
    # Download handler for cluster data
    output$download_clusters <- downloadHandler(
      filename = function() {
        paste0("cluster_assignments_", input$distance_method, "_", input$cluster_method, "_h", input$cut_height, ".csv")
      },
      content = function(file) {
        # Get cluster assignments at specified height
        clusters <- cutree(df_clusters(), h = input$cut_height)
        
        # Create data frame with row labels and cluster assignments
        cluster_data <- data.frame(
          row_label = names(clusters),
          cluster = clusters,
          stringsAsFactors = FALSE
        )
        
        write.csv(cluster_data, file, row.names = FALSE)
      }
    )
    
    # Download handler for image export
    output$download_image <- downloadHandler(
      filename = function() {
        zoom_suffix <- if (!is.null(ranges$x) || !is.null(ranges$y)) "_zoomed" else "_full"
        paste0("dendrogram_", input$distance_method, "_", input$cluster_method, "_h", input$cut_height, zoom_suffix, ".png")
      },
      content = function(file) {
        # Generate the same plot as displayed
        # Get cluster assignments at specified height
        clusters <- cutree(df_clusters(), h = input$cut_height)

        # Add cluster colors to labels
        dendro_labels <- dendro_df()$labels
        dendro_labels$cluster <- clusters[dendro_labels$label]
        dendro_labels$cluster <- as.factor(dendro_labels$cluster)

        # Find all segments that cross the cut height (create cluster boundaries)
        cluster_segments <- dendro_df()$segments |>
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
            data = dendro_df()$segments,
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
            legend.position = "none",
            plot.margin = margin(t = 20, r = 20, b = 20, l = 120, unit = "pt")
          ) +
          labs(title = paste("Distance:", input$distance_method, "| Clustering:", input$cluster_method, "| Cut height:", input$cut_height), y = "", x = "Cut height") +
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
        
        # Save the plot as PNG
        ggsave(file, p, width = 16, height = 10, dpi = 300, units = "in")
      }
    )
  }

  shinyApp(ui, server)
}

# Run the app
create_zoom_tree()
