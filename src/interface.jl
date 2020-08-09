function paint_text!(background, textimgs, textqts, shiftx, shifty)
    for (img, qt) in zip(textimgs, textqts)
        py, px = QTree.getshift(qt[1])
        overlay!(background, img, px-shiftx+1, py-shifty+1)
    end
    background
end