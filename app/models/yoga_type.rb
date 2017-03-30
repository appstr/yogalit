class YogaType < ActiveRecord::Base
  belongs_to :teacher

  ENUMS = {
    "Bikram"           => 1,
    "Ashtanga"         => 2,
    "Beginner Yoga"    => 3,
    "Fusion"           => 4,
    "Hatha"            => 5,
    "Kids"             => 6,
    "Kundalini"        => 7,
    "Meditation"       => 8,
    "Power"            => 9,
    "Pre/Postnatal"    => 10,
    "Restorative"      => 11,
    "Vinyasa"          => 12,
    "Yin Yoga"         => 13,
    "Yoga at Work"     => 14,
    "Yoga for Seniors" => 15,
    "Pilates"          => 16,
    "Iyengar"          => 17,
  }
end
