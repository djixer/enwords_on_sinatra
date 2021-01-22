class Words < ActiveRecord::Migration[5.2]
  def change
  	create_table :words do |t|
  		t.text :eng_word
  		t.text :rus_word
  		t.integer :right_answers, :null => false, :default => 0
  		t.integer :wrong_answers, :null => false, :default => 0

  		t.timestamps
  	end
  end
end
