# Interactive Dendrogram Explorer

An interactive R Shiny application for exploring hierarchical clustering patterns in yeast metal tolerance data through zoomable dendrograms.

## Background

This application visualizes yeast metal tolerance data from Grossjean, et. al., 2022. Genome-Wide Mutant Screening in Yeast Reveals that the Cell Wall is a First Shield to Discriminate Light From Heavy Lanthanides. Frontiers in Microbiology (https://doi.org/10.3389/fmicb.2022.881535), allowing users to interactively explore clustering patterns of 630 yeast gene mutants based on their tolerance to 12 different metals (As, Cd, Co, Cr, Cu, Fe, La, Mn, Ni, Y, Yb, Zn).

## Features

### Interactive Clustering
- **Dynamic Cut Height**: Adjust clustering granularity with a simple slider
- **Real-time Cluster Visualization**: See cluster assignments update instantly
- **Color-coded Groups**: Each cluster gets a unique, high-contrast color

### Navigation & Zoom
- **Brush-to-Zoom**: Click and drag to zoom into specific dendrogram regions
- **Label Search**: Find and zoom to specific yeast genes by name
- **Reset View**: Easily return to the full dendrogram view

### Visual Elements
- Clean, publication-ready dendrogram layout
- Cluster boundary indicators with numbered labels
- Responsive design with intuitive controls

## Getting Started

### Prerequisites
```r
# Required R packages
install.packages(c("shiny", "tidyverse", "ggdendro"))
```

### Running the Application
1. Clone this repository:
   ```bash
   git clone https://github.com/wendysphillips/interactive_dendrogram.git
   cd interactive_dendrogram
   ```

2. Launch the Shiny app:
   ```r
   # In R console
   source("shiny_dendrogram.r")
   create_zoom_tree()
   ```

The application will open in your default web browser.

## Project Structure

```
interactive_dendrogram/
├── shiny_dendrogram.r          # Main Shiny application
├── generate_colors.R           # Color palette generator
├── yeast_metal_tolerances.tsv  # Dataset (630 genes × 12 metals)
├── README.md                   # This file
└── LICENSE                     # MIT License
```

## How to Use

1. **Adjust Clustering**: Use the "Cut Height" slider to change how many clusters are formed
2. **Explore Regions**: Click and drag on the dendrogram to zoom into specific areas
3. **Find Genes**: Enter a yeast gene name (e.g., "YAL053W") and click "Zoom to Label"
4. **Reset View**: Click "Reset Zoom" to return to the full dendrogram

## Data Format

The application expects tab-separated data with:
- **First column**: Unique identifiers to be clustered
- **Remaining columns**: Numeric values for clustering

### Using Your Own Data

While this example uses yeast metal tolerance data, you can easily substitute any dataset that is amenable to hierarchical clustering. Simply replace the `yeast_metal_tolerances.tsv` file with your own tab-separated data file that follows the same format:

- Row identifiers in the first column
- Numeric data suitable for clustering in subsequent columns
- Ensure your data is properly scaled if variables have different units

The application will automatically adapt to datasets of different sizes and variable types, making it a versatile tool for exploring clustering patterns in any quantitative dataset.

## Technical Details

- **Clustering Method**: Ward's method (ward.D2) with Euclidean distance
- **Visualization**: ggplot2 with ggdendro for dendrogram rendering
- **Interactivity**: Shiny reactive framework for real-time updates


## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [Original Research Paper](https://doi.org/10.3389/fmicb.2022.881535)
- [R Shiny Documentation](https://shiny.rstudio.com/)
- [ggdendro Package](https://cran.r-project.org/package=ggdendro)
