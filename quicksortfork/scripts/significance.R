library(dplyr)
library(tidyr)

dir <- "data/ensietuHP02_2026-11-11"
files <- list.files(dir, pattern = "^measurements_.*\\.csv$", full.names = TRUE)
df <- bind_rows(lapply(files, function(f) {
  d <- read.csv(f)
  d$Build <- sub("measurements_(.*)_[0-9]{2}-[0-9]{2}\\.csv", "\\1", basename(f))
  d
}))

res <- df %>%
  filter(Type %in% c("Sequential", "Parallel")) %>%
  select(Build, Size, Rep, Type, Time) %>%
  pivot_wider(names_from = Type, values_from = Time) %>%
  mutate(diff = Parallel - Sequential) %>%
  group_by(Build, Size) %>%
  summarise(n = n(), mean_diff = mean(diff),
            ci = qt(0.975, n - 1) * sd(diff) / sqrt(n), .groups = "drop") %>%
  mutate(lo = mean_diff - ci, hi = mean_diff + ci,
         verdict = case_when(hi < 0 ~ "parallel faster",
                             lo > 0 ~ "sequential faster",
                             TRUE ~ "no significant difference"))

print(as.data.frame(res %>% filter(Build %in% c("pq_O2_L1", "pq_O2_L2"), Size >= 2000000)), digits = 3)
cat("\n--- pqr (thread-safe pivot) ---\n")
print(as.data.frame(res %>% filter(Build %in% c("pqr_O2_L4","pqr_O2_L10"), Size >= 50000)), digits = 3)
