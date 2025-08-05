# Interactive Dendrogram Explorer

An interactive R Shiny application for exploring hierarchical clustering patterns using various distance and clustering methods through zoomable dendrograms.

## Background

The example data used for this application is yeast metal tolerance data from Grossjean, et. al., 2022. Genome-Wide Mutant Screening in Yeast Reveals that the Cell Wall is a First Shield to Discriminate Light From Heavy Lanthanides. Frontiers in Microbiology (https://doi.org/10.3389/fmicb.2022.881535). With these data, users can interactively explore clustering patterns of 630 yeast gene mutants based on their tolerance to 12 different metals (As, Cd, Co, Cr, Cu, Fe, La, Mn, Ni, Y, Yb, Zn).

## Features

### Interactive Clustering
- **Multiple Distance Methods**: Choose from Manhattan, Euclidean, Maximum, or Binary distance calculations
- **Multiple Clustering Methods**: Select from Complete, Single, Average, or Ward.D2 linkage methods
- **Dynamic Cut Height**: Adjust clustering granularity
- **Real-time Cluster Visualization**: See cluster assignments update instantly as you change parameters
- **Color-coded Groups**: Each cluster gets a unique, high-contrast color

### Navigation & Zoom
- **Brush-to-Zoom**: Click and drag to zoom into specific dendrogram regions
- **Label Search**: Find and zoom to specific yeast genes by name
- **Reset View**: Easily return to the full dendrogram view

### Data Export
- **Cluster Export**: Download cluster assignments as CSV files with current settings
- **Filename includes parameters**: Exported files are automatically named with distance method, clustering method, and cut height

### Visual Elements
- Clean, publication-ready dendrogram layout
- Cluster boundary indicators with numbered labels
- Responsive design with intuitive controls
- Real-time parameter display in plot title

## Getting Started

### Prerequisites
```r
# Required R packages
install.packages(c("shiny", "dplyr", "ggplot2", "tibble", "ggdendro"))
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

1. **Select Methods**: Choose your preferred distance calculation and clustering method from the dropdowns
2. **Adjust Clustering**: Use the "Cut Height" slider to change how many clusters are formed
3. **Explore Regions**: Click and drag on the dendrogram to zoom into specific areas
4. **Find Genes**: Enter a yeast gene name (e.g., "YAL053W") and click "Zoom to Label"
5. **Export Data**: Click "Export Cluster Data" to download cluster assignments as a CSV file
6. **Reset View**: Click "Reset Zoom" to return to the full dendrogram

### Using Your Own Data

While this example uses yeast metal tolerance data, you can easily substitute any dataset that is amenable to hierarchical clustering. Simply replace the `yeast_metal_tolerances.tsv` file with your own tab-separated data file that follows the same format:

- Labels (e.g. genes) to be clustered in the first column (column unnamed)
- Numeric data suitable for clustering in subsequent columns
- Ensure your data is properly scaled if variables have different units

The application will automatically adapt to datasets of different sizes and variable types, making it a versatile tool for exploring clustering patterns in any quantitative dataset.

## Technical Details

- **Distance Methods**: Manhattan, Euclidean, Maximum, Binary (optimized for discrete data)
- **Clustering Methods**: Complete, Single, Average, Ward.D2 (selected for stability with discrete values)
- **Visualization**: ggplot2 with ggdendro for dendrogram rendering
- **Interactivity**: Shiny reactive framework for real-time updates
- **Data Export**: CSV format with row labels and cluster assignments
- **Image Export**: PNG format at 300 DPI for publication-quality images


## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## Authors

This pipeline was developed jointly by **Wendy Phillips** and **GitHub Copilot** through collaborative AI-assisted programming.

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [Original Research Paper](https://doi.org/10.3389/fmicb.2022.881535)
- [R Shiny Documentation](https://shiny.rstudio.com/)
- [ggdendro Package](https://cran.r-project.org/package=ggdendro)
