#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript overnight_plot.R <run_csv> <summary_csv> <out_dir>")
}

run_csv <- args[[1]]
summary_csv <- args[[2]]
out_dir <- args[[3]]
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

run_df <- read_csv(run_csv, show_col_types = FALSE)
summary_df <- read_csv(summary_csv, show_col_types = FALSE)

run_df <- run_df %>%
  mutate(
    agtCnt = as.factor(agtCnt),
    p95_median_ratio = as.numeric(p95_median_ratio),
    median_price = as.numeric(median_price),
    sales_n = as.numeric(sales_n)
  )

summary_df <- summary_df %>%
  mutate(
    agtCnt = as.factor(agtCnt),
    ratio_median = as.numeric(ratio_median),
    ratio_p75 = as.numeric(ratio_p75),
    ratio_max = as.numeric(ratio_max)
  )

p1 <- ggplot(run_df, aes(x = agtCnt, y = p95_median_ratio)) +
  geom_boxplot(fill = "#90caf9", color = "#0d47a1", outlier.alpha = 0.5) +
  geom_jitter(width = 0.12, alpha = 0.5, size = 1.8, color = "#1565c0") +
  labs(
    title = "Tail Volatility by Market Scale",
    subtitle = "Per-run p95/median sale-price ratio",
    x = "Agent Count",
    y = "p95 / median"
  ) +
  theme_minimal(base_size = 13)

p2 <- ggplot(run_df, aes(x = agtCnt, y = sales_n)) +
  geom_boxplot(fill = "#a5d6a7", color = "#1b5e20", outlier.alpha = 0.5) +
  geom_jitter(width = 0.12, alpha = 0.5, size = 1.8, color = "#2e7d32") +
  labs(
    title = "Sales Count by Market Scale",
    subtitle = "Per-run completed sales",
    x = "Agent Count",
    y = "Sales Count"
  ) +
  theme_minimal(base_size = 13)

p3 <- ggplot(run_df, aes(x = agtCnt, y = median_price)) +
  geom_boxplot(fill = "#ffcc80", color = "#e65100", outlier.alpha = 0.5) +
  geom_jitter(width = 0.12, alpha = 0.5, size = 1.8, color = "#ef6c00") +
  labs(
    title = "Median Sale Price by Market Scale",
    subtitle = "Per-run median sale price",
    x = "Agent Count",
    y = "Median Price"
  ) +
  theme_minimal(base_size = 13)

p4 <- ggplot(summary_df, aes(x = agtCnt, y = ratio_median, group = 1)) +
  geom_line(color = "#6a1b9a", linewidth = 1.1) +
  geom_point(color = "#4a148c", size = 2.5) +
  labs(
    title = "Scale Curve: Median Tail Volatility",
    subtitle = "Summary-table ratio_median by scale",
    x = "Agent Count",
    y = "Median(p95 / median)"
  ) +
  theme_minimal(base_size = 13)

ggsave(file.path(out_dir, "tail_volatility_boxplot.png"), p1, width = 10, height = 6, dpi = 150)
ggsave(file.path(out_dir, "sales_count_boxplot.png"), p2, width = 10, height = 6, dpi = 150)
ggsave(file.path(out_dir, "median_price_boxplot.png"), p3, width = 10, height = 6, dpi = 150)
ggsave(file.path(out_dir, "scale_curve_ratio_median.png"), p4, width = 10, height = 6, dpi = 150)

cat("Wrote plots to:", out_dir, "\n")
