library(ggplot2)
library(dplyr)

dir <- "data/ensietuHP02_2026-11-11"
files <- list.files(dir, pattern = "^measurements_.*\\.csv$", full.names = TRUE)

df <- bind_rows(lapply(files, function(f) {
  d <- read.csv(f)
  d$Build <- sub("measurements_(.*)_[0-9]{2}-[0-9]{2}\\.csv", "\\1", basename(f))
  d
}))

# mean and 95% confidence interval per (Build, Type, Size)
summ <- df %>%
  group_by(Build, Type, Size) %>%
  summarise(n = n(), mean = mean(Time), sd = sd(Time),
            ci = qt(0.975, n - 1) * sd / sqrt(n), .groups = "drop")

p <- ggplot(summ, aes(Size, mean, color = Type)) +
  geom_line() + geom_point() +
  geom_ribbon(aes(ymin = pmax(mean - ci, 1e-7), ymax = mean + ci, fill = Type),
              alpha = 0.2, color = NA) +
  scale_x_log10() + scale_y_log10() +
  facet_wrap(~Build) +
  labs(x = "Array size", y = "Time (s)",
       title = "Quicksort: sequential vs parallel vs built-in")

ggsave(file.path(dir, "comparison.png"), p, width = 10, height = 5)

# table: sequential vs parallel mean time and the ratio (ratio < 1 means parallel is faster)
wide <- summ %>%
  filter(Type %in% c("Sequential", "Parallel")) %>%
  select(Build, Type, Size, mean) %>%
  tidyr::pivot_wider(names_from = Type, values_from = mean) %>%
  mutate(Ratio_Par_over_Seq = Parallel / Sequential)

print(as.data.frame(wide), digits = 3)
