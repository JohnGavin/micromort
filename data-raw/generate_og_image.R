# Generate OG image (1200x630px) for social media sharing
# Run: source("data-raw/generate_og_image.R")

library(ggplot2)

# Mini risk ladder data: 6 iconic activities
ladder <- data.frame(

  activity = c(
    "Cup of coffee", "Skiing (1 day)", "Skydiving",
    "General anesthesia", "Base jumping", "Mt. Everest ascent"
  ),
  micromorts = c(0.01, 0.7, 10, 10, 430, 37932),
  stringsAsFactors = FALSE
)
ladder$activity <- factor(ladder$activity, levels = ladder$activity)

p <- ggplot(ladder, aes(x = micromorts, y = activity)) +
  geom_col(fill = "#4ecdc4", width = 0.6) +
  geom_text(
    aes(label = paste0(micromorts, " mm")),
    hjust = -0.1, color = "white", size = 4.5, fontface = "bold"
  ) +
  scale_x_log10(
    limits = c(0.005, 200000),
    labels = scales::label_comma()
  ) +
  labs(
    title = "micromort",
    subtitle = "Which lifestyle event is more likely to kill you?",
    x = NULL, y = NULL
  ) +
  theme(
    plot.background = element_rect(fill = "#1a1a1a", color = NA),
    panel.background = element_rect(fill = "#1a1a1a", color = NA),
    panel.grid.major.x = element_line(color = "#333333", linetype = "dashed", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    text = element_text(color = "white"),
    axis.text = element_text(color = "white", size = 12),
    axis.text.y = element_text(face = "bold", color = "white", size = 13),
    plot.title = element_text(size = 28, face = "bold", color = "#4ecdc4", hjust = 0.5),
    plot.subtitle = element_text(size = 14, color = "#cccccc", hjust = 0.5),
    plot.margin = margin(20, 40, 20, 20)
  )

ggsave(
  "man/figures/og-image.png", p,
  width = 1200 / 96, height = 630 / 96, dpi = 96,
  bg = "#1a1a1a"
)
message("OG image saved to man/figures/og-image.png")
