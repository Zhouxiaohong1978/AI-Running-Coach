### **AI**跑步教练** PRD v1.0**

****版本**:** 1.0 (**阿里云百炼**, iOS16+)  

****日期**:** 2026.1.28  

****概述****: GPS + AI**语音教练** + **成就**, 4**周**MVP.

**P0**功能****:

1. **GPS**轨迹****: MapKit**实时**, **精度**<10m. AC: **无漂移**. **技术**: LocationManager (95%**复用**).

2. **AI**训练****: **百炼生成计划**JSON. 

3. **AI**语音****: "**配速好**, **加油**!". AC: <2s, AirPods. **技术**: SpeechManager + **百炼**prompt.

4. ****成就****: EventBus**触发**.

5. ****登录****: Supabase Auth.

****技术栈****: SwiftUI, Supabase PostGIS, **阿里云百炼**, RevenueCat.

****数据****:

```sql
users (id uuid PK, total_distance float);

runs (id uuid PK, user_id uuid, geometry geography(linestring,4326));

training_plans (id uuid PK, user_id uuid, plan_json jsonb);
```

****里程碑****:

| M | **内容** | **周** |

|---|------|----|

| M1 | Auth+GPS | 1 |

| M2 | AI+**语音** | 2 |

| M3 | **成就**+**订阅** | 3 |

| M4 | **上架** | 4 |

**Claude**指令****: **生成**P0, iOS16+**语音优化**.

```

---

#### 
