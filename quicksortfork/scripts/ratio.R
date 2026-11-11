library(dplyr); library(tidyr); library(ggplot2)
dir <- "data/ensietuHP02_2026-11-11"
files <- list.files(dir, pattern = "^measurements_.*\\.csv$", full.names = TRUE)
df <- bind_rows(lapply(files, function(f) {
  d <- read.csv(f)
  d$Build <- sub("measurements_(.*)_[0-9]{2}-[0-9]{2}\\.csv", "\\1", basename(f))
  d
}))
r <- df %>% filter(Type %in% c("Sequential","Parallel")) %>%
  select(Build, Size, Rep, Type, Time) %>%
  pivot_wider(names_from = Type, values_from = Time) %>%
  mutate(ratio = Parallel / Sequential) %>%
  group_by(Build, Size) %>%
  summarise(n = n(), m = mean(ratio),
            ci = qt(0.975, n-1) * sd(ratio) / sqrt(n), .groups = "drop") %>%
  filter(TRUE)
p <- ggplot(r, aes(Size, m, color = Build)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_line() + geom_point() +
  geom_errorbar(aes(ymin = m - ci, ymax = m + ci), width = 0.05) +
  scale_x_log10() + scale_y_log10() +
  labs(x = "Array size", y = "Parallel time / Sequential time (below 1 = parallel wins)")
ggsave(file.path(dir, "ratio.png"), p, width = 8, height = 5)
print(as.data.frame(r %>% filter(Size >= 100000, Build %in% c("pq_O2_L1","pq_O2_L2","pqr_O2_L1","pqr_O2_L2","pqr_O2_L10","pqr_O2_L4","ctrl_L1","ctrl_L2","ctrl_L4","ctrl_L10"))), digits = 3)
