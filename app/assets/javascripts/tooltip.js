$(document).ready(function() {
    var tooltipHtml = `
    <div>
    <div class="tooltipClose">×</div>
        <div style="margin: 10px;">
        <div>
            ツールチップが表示されたよ！<br>
            下は、とらラボのリンクだよ<br>
            <a target="_blank" href="https://yumenosora.co.jp/tora-lab">とらラボ</a>
        </div>
        </div>
    </div>
    </div>`;

    $(".showTooltip").tooltip({
        content: tooltipHtml
    });
});