import Foundation

enum DevBlossomSeedData {
    // Raw Blossom export JSON (summary) embedded for one-time import.
    static let json: String = """
[
  {
    "plant_internal_id":"51206",
    "plantId_numeric":2674,
    "name":"Burgundy Rubber Plant",
    "room":"Dining room",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":24.8920004845,
    "pot_diameter_cm":20.32
  },
  {
    "plant_internal_id":"51213",
    "plantId_numeric":341,
    "name":"ZZ Plant",
    "room":"Dining room",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":17.5260002422,
    "pot_diameter_cm":15.24
  },
  {
    "plant_internal_id":"51221",
    "plantId_numeric":327,
    "name":"Aloe Vera",
    "room":"Office",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":"GLAZED_CERAMICS",
    "pot_height_cm":12.7,
    "pot_diameter_cm":12.7
  },
  {
    "plant_internal_id":"51229",
    "plantId_numeric":73,
    "name":"Maranta Prayer Plant",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":17.78,
    "pot_diameter_cm":13.97
  },
  {
    "plant_internal_id":"51239",
    "plantId_numeric":436,
    "name":"Rattlesnake Plant",
    "room":"Office",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":24.13,
    "pot_diameter_cm":16.51
  },
  {
    "plant_internal_id":"51247",
    "plantId_numeric":217,
    "name":"Snake Plant",
    "room":"Living room",
    "kindOfLight":"LOW",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":20.32,
    "pot_diameter_cm":21.59
  },
  {
    "plant_internal_id":"51257",
    "plantId_numeric":303,
    "name":"Fiddle Leaf Fig Tree",
    "room":"Dining room",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":27.94,
    "pot_diameter_cm":18.7960002422
  },
  {
    "plant_internal_id":"51267",
    "plantId_numeric":1321,
    "name":"Monstera Deliciosa",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":24.13,
    "pot_diameter_cm":20.32
  },
  {
    "plant_internal_id":"51275",
    "plantId_numeric":2825,
    "name":"Key Lime Tree",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":43.18,
    "pot_diameter_cm":15.24
  },
  {
    "plant_internal_id":"51285",
    "plantId_numeric":365,
    "name":"Chinese Money Plant",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":13.97,
    "pot_diameter_cm":12.7
  },
  {
    "plant_internal_id":"51295",
    "plantId_numeric":75,
    "name":"Coffee",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":24.13,
    "pot_diameter_cm":16.51
  },
  {
    "plant_internal_id":"51305",
    "plantId_numeric":950,
    "name":"Jade Plant",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":11.43,
    "pot_diameter_cm":11.43
  },
  {
    "plant_internal_id":"51316",
    "plantId_numeric":1868,
    "name":"Hilo Beauty",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":16.51,
    "pot_diameter_cm":11.43
  },
  {
    "plant_internal_id":"51323",
    "plantId_numeric":2780,
    "name":"Mammillaria - Irishman",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":7.8740003633,
    "pot_diameter_cm":7.8740003633
  },
  {
    "plant_internal_id":"51333",
    "plantId_numeric":369,
    "name":"Golden Barrel Cactus",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":10.16,
    "pot_diameter_cm":7.8740003633
  },
  {
    "plant_internal_id":"51344",
    "plantId_numeric":1101,
    "name":"Christmas Cactus",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":10.16,
    "pot_diameter_cm":9.1440003633
  },
  {
    "plant_internal_id":"51355",
    "plantId_numeric":1515,
    "name":"Blue Torch Column Cactus ",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":7.62,
    "pot_diameter_cm":7.62
  },
  {
    "plant_internal_id":"51362",
    "plantId_numeric":34,
    "name":"Golden Pothos",
    "room":"Office",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":10.16,
    "pot_diameter_cm":10.16
  },
  {
    "plant_internal_id":"51369",
    "plantId_numeric":750,
    "name":"Bunny Ear Cactus white",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"GLAZED_CERAMICS",
    "pot_height_cm":5.08,
    "pot_diameter_cm":5.08
  },
  {
    "plant_internal_id":"51379",
    "plantId_numeric":750,
    "name":"Bunny Ear Cactus",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":14.2239997578,
    "pot_diameter_cm":11.6839997578
  },
  {
    "plant_internal_id":"51386",
    "plantId_numeric":304,
    "name":"India Rubber Plant",
    "room":"Dining room",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":12.7,
    "pot_diameter_cm":11.43
  },
  {
    "plant_internal_id":"51396",
    "plantId_numeric":217,
    "name":"Snake Plant Norma",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":20.0660002422,
    "pot_diameter_cm":21.59
  },
  {
    "plant_internal_id":"51403",
    "plantId_numeric":-33872155,
    "name":"Escobaria vivipara (Nutt.) Buxb.",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":10.16,
    "pot_diameter_cm":6.35
  },
  {
    "plant_internal_id":"51413",
    "plantId_numeric":937,
    "name":"Hibiscus",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":15.24,
    "pot_diameter_cm":15.24
  },
  {
    "plant_internal_id":"51420",
    "plantId_numeric":1125,
    "name":"Tuberous Begonia",
    "room":"Office",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":20.32,
    "pot_diameter_cm":15.24
  },
  {
    "plant_internal_id":"51430",
    "plantId_numeric":303,
    "name":"Lil Fiddle",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":15.24,
    "pot_diameter_cm":15.24
  },
  {
    "plant_internal_id":"51438",
    "plantId_numeric":750,
    "name":"Bunny Ear Cactus IKEA ",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":6.35,
    "pot_diameter_cm":5.08
  },
  {
    "plant_internal_id":"51447",
    "plantId_numeric":373,
    "name":"Heart of Jesus ",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":16.51,
    "pot_diameter_cm":11.43
  },
  {
    "plant_internal_id":"51456",
    "plantId_numeric":270,
    "name":"Peace Lily",
    "room":"Dining room",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":17.78,
    "pot_diameter_cm":17.78
  },
  {
    "plant_internal_id":"51464",
    "plantId_numeric":106,
    "name":"Flowering Tobacco (Nicotiana)",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":15.7480007267,
    "pot_diameter_cm":15.4939997578
  },
  {
    "plant_internal_id":"51472",
    "plantId_numeric":3448,
    "name":"Emory's Barrel Cactus",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":10.16,
    "pot_diameter_cm":6.35
  },
  {
    "plant_internal_id":"51479",
    "plantId_numeric":1515,
    "name":"Neoraimondia herzogiana",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":10.16,
    "pot_diameter_cm":6.35
  },
  {
    "plant_internal_id":"51487",
    "plantId_numeric":2780,
    "name":"Mammillaria disco",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":8.89,
    "pot_diameter_cm":6.35
  },
  {
    "plant_internal_id":"51494",
    "plantId_numeric":365,
    "name":"Chinese Money Plant head",
    "room":"Kitchen",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":8.1280001211,
    "pot_diameter_cm":7.62
  },
  {
    "plant_internal_id":"51501",
    "plantId_numeric":1579,
    "name":"Philodendron Birkin",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":12.7,
    "pot_diameter_cm":7.62
  },
  {
    "plant_internal_id":"51511",
    "plantId_numeric":1891,
    "name":"Pink Princess Philodendron",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"TERRACOTA",
    "pot_height_cm":17.2720004845,
    "pot_diameter_cm":11.43
  },
  {
    "plant_internal_id":"51518",
    "plantId_numeric":950,
    "name":"Jade Plant (transfer)",
    "room":"Kitchen",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":15.24,
    "pot_diameter_cm":12.7
  },
  {
    "plant_internal_id":"51528",
    "plantId_numeric":254,
    "name":"Hanging Wandering Jew",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":12.7,
    "pot_diameter_cm":10.16
  },
  {
    "plant_internal_id":"51537",
    "plantId_numeric":358,
    "name":"Croton",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":11.9380007267,
    "pot_diameter_cm":8.89
  },
  {
    "plant_internal_id":"51547",
    "plantId_numeric":1172,
    "name":"Kishu Mandarin",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":"PLASTIC",
    "pot_height_cm":30.48,
    "pot_diameter_cm":17.78
  },
  {
    "plant_internal_id":"51556",
    "plantId_numeric":279,
    "name":"Rex Begonia prop",
    "room":"Office",
    "kindOfLight":"MEDIUM",
    "sideLocation":"INSIDE",
    "pot_material":"GLAZED_CERAMICS",
    "pot_height_cm":12.7,
    "pot_diameter_cm":8.89
  },
  {
    "plant_internal_id":"51566",
    "plantId_numeric":983,
    "name":"Elephant Ears",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":25.4,
    "pot_diameter_cm":22.86
  },
  {
    "plant_internal_id":"51573",
    "plantId_numeric":75,
    "name":"Coffee black pot",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":12.7,
    "pot_diameter_cm":10.16
  },
  {
    "plant_internal_id":"51580",
    "plantId_numeric":341,
    "name":"ZZ Prop",
    "room":"Office",
    "kindOfLight":"BRIGHT_DIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":13.97,
    "pot_diameter_cm":11.43
  },
  {
    "plant_internal_id":"51589",
    "plantId_numeric":328,
    "name":"Lotus",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":16.51,
    "pot_diameter_cm":17.5260002422
  },
  {
    "plant_internal_id":"51597",
    "plantId_numeric":243,
    "name":"Persian Shield",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":10.16,
    "pot_diameter_cm":10.16
  },
  {
    "plant_internal_id":"51604",
    "plantId_numeric":1717,
    "name":"Calathea Ornata",
    "room":"Office",
    "kindOfLight":"BRIGHT_INDIRECT",
    "sideLocation":"INSIDE",
    "pot_material":null,
    "pot_height_cm":10.4139997578,
    "pot_diameter_cm":15.24
  }
]
"""
}

